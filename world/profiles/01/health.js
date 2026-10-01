// Scenario 01: the world is already calling.
// A probe every 5 s, a steady 20 req/s from 10 keep-alive clients, and the odd request for a
// path that doesn't exist. Runs for 30 days and systemd restarts it, so effectively forever.
import http from 'k6/http';
import { check } from 'k6';

const APP = __ENV.APP_HOST || 'http://127.0.0.1:8080';
const LONG = '30d';

export const options = {
  scenarios: {
    probe:  { executor: 'constant-arrival-rate', exec: 'probe',  rate: 1,  timeUnit: '5s',  duration: LONG, preAllocatedVUs: 1, maxVUs: 1 },
    steady: { executor: 'constant-arrival-rate', exec: 'health', rate: 20, timeUnit: '1s',  duration: LONG, preAllocatedVUs: 10, maxVUs: 10 },
    other:  { executor: 'constant-arrival-rate', exec: 'other',  rate: 1,  timeUnit: '10s', duration: LONG, preAllocatedVUs: 1, maxVUs: 1 },
  },
};

const T = { timeout: '2s' };

function healthCheck(r) {
  check(r, {
    'status 200': (x) => x.status === 200,
    'body ok': (x) => x.body === 'ok',
    'under 50ms': (x) => x.timings.duration < 50,
  });
}

export function probe()  { healthCheck(http.get(`${APP}/health`, { ...T, tags: { name: 'GET /health', kind: 'probe' } })); }
export function health() { healthCheck(http.get(`${APP}/health`, { ...T, tags: { name: 'GET /health', kind: 'steady' } })); }
export function other() {
  const r = http.get(`${APP}/definitely-not-here`, { ...T, tags: { name: 'GET other' }, responseCallback: http.expectedStatuses(404) });
  check(r, { 'status 404': (x) => x.status === 404 });
}

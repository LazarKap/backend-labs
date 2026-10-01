# Cheat sheet: watching failures from the server side

Real service names from the provisioning. Replace `<app-ip>` with the value from the private notes.

## On world

| Want to know | Command |
|---|---|
| What is the runner doing right now | `journalctl -u k6-profile -f` |
| Failures in the last hour, grouped | `journalctl -u k6-profile --since -1h -o cat \| grep -o 'error="[^"]*"' \| sort \| uniq -c \| sort -rn` |
| Send one request and see every byte back | `curl -v http://<app-ip>:8080/health` |
| Talk HTTP by hand | `printf 'GET /health HTTP/1.1\r\nHost: x\r\n\r\n' \| nc <app-ip> 8080` |
| Keep-alive, two requests on one connection | `printf 'GET /health HTTP/1.1\r\nHost: x\r\n\r\nGET /health HTTP/1.1\r\nHost: x\r\n\r\n' \| nc <app-ip> 8080` |
| How many connections world has open to the app | `ss -tan '( dport = :8080 )' \| awk 'NR>1{print $1}' \| sort \| uniq -c` |
| Packets on the wire, readable | `tcpdump -i eth0 -A -s0 'host <app-ip> and port 8080'` |
| Ask Prometheus directly | `curl -s localhost:9090/api/v1/query --data-urlencode 'query=sum by (status) (rate(k6_http_reqs_total[1m]))' \| python3 -m json.tool` |
| Is Prometheus getting data | `curl -s 'localhost:9090/api/v1/query?query=count(k6_http_reqs_total)'` |
| Grafana alive | `curl -s localhost:3000/api/health` |

## On app

| Want to know | Command |
|---|---|
| Your own logs, live | `journalctl -u app -f` |
| Is the process up, restarts, memory | `systemctl status app` |
| Connections by state | `ss -tan '( sport = :8080 )' \| awk 'NR>1{print $1}' \| sort \| uniq -c` |
| Open file descriptors (the slowloris number) | `ls /proc/$(pidof app)/fd \| wc -l` and the limit: `cat /proc/$(pidof app)/limits \| grep 'open files'` |
| Listening at all | `ss -tlnp \| grep 8080` |
| CPU or memory bound | `htop` (`apt install htop`) or `top -p $(pidof app)` |
| What the kernel is doing for one request | `strace -f -p $(pidof app) -e trace=network,read,write` for a few seconds, then Ctrl-C |
| Accept queue overflowing | `ss -tlne \| grep 8080` and `nstat -az TcpExtListenOverflows TcpExtListenDrops` |
| Goroutines, heap, from inside | your problem to expose, scenario 03 |

## Reading a k6 failure line

```
level=warning msg="Request Failed" error="Get \"http://<app-ip>:8080/health\": request timeout"
```

`request timeout` = connected, no complete response in 2 s. `dial tcp ... connect: connection refused`
= nothing listening. `EOF` = the server closed the connection mid-response. `connection reset by peer`
= the server (or kernel) killed it. `context deadline exceeded` on dial = SYN never answered, usually a
firewall or a full accept queue.

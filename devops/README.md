# DevOps Infrastructure Stack

This directory contains configuration for the infrastructure stack (Inf Stack) including monitoring, databases, and DNS.

## Infrastructure Services

- [**Grafana**](README.grafana.md) - Dashboards and visualization
- [**Prometheus**](README.prometheus.md) - Metrics collection and alerting
- [**InfluxDB**](README.influxdb.md) - Time series database
- [**MySQL**](README.mysql.md) - Relational database
- [**Pushgateway**](README.pushgateway.md) - Metric pusher for batch jobs
- [**CoreDNS**](README.core_dns.md) - Local service discovery (DNS)
- [**Node Exporter**](README.node_exporter.md) - Hardware/OS metrics

## Control Commands

### Docker (Colima)

```makefile
start:
 colima start
 colima status
 docker context use colima

stop:
 colima status
 colima stop
```

### DNS Operations

```bash
# reset Mac DNS
sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder

# test for domain
ping grafafa.test
dig @127.0.0.1 -p 10053 grafana.test
dscacheutil -q host -a name grafana.test
```

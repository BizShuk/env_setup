# Prometheus Setup Guide

Prometheus is an open-source systems monitoring and alerting toolkit.

## Quick Start

### 1. Start Prometheus Container

```bash
cd devops
docker-compose up -d prometheus
```

### 2. Access Web UI

- **URL**: <http://localhost:9090>
- **Status**: Check **Status** -> **Targets** to see active scrape jobs.

## Configuration

The configuration is located at `devops/prometheus.yml` (in the root if using docker-compose, or see `devops/grafana/prometheus/prometheus.yml`).

### Scrape Jobs

As defined in `prometheus.yml`:

- **prometheus**: Scrapes itself on port 9090.
- **pushgateway**: Scrapes the Pushgateway on port 9091.
- **node_exporter**: Scrapes system metrics on port 9100.
- **app**: Scrapes application metrics on port 8080.

## Useful Queries (PromQL)

```promql
# CPU usage
rate(node_cpu_seconds_total{mode="idle"}[5m])

# Memory usage
node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes * 100

# Disk usage
node_filesystem_avail_bytes{mountpoint="/"}

# Network traffic
rate(node_network_receive_bytes_total[5m])

# Check if application is up
up{job="app"}
```

## Maintenance (Bare Metal)

If not using Docker, see `devops/grafana/prometheus/setup.sh` for manual installation steps on Linux.

```bash
# Manual setup script
./devops/grafana/prometheus/setup.sh
```

## References

- [Prometheus Documentation](https://prometheus.io/docs/introduction/overview/)
- [Grafana Integration](README.grafana.md)

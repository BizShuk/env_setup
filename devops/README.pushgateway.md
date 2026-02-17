# Prometheus Pushgateway

The Pushgateway is an intermediary service which allows you to push metrics from jobs which cannot be scraped (e.g., ephemeral batch jobs).

## Quick Start

### 1. Start Pushgateway Container

```bash
cd devops
docker-compose up -d pushgateway
```

### 2. Access Web UI

- **URL**: <http://localhost:9091>

## Pushing Metrics

You can push metrics using `curl`:

```bash
echo "some_metric 3.14" | curl --data-binary @- http://localhost:9091/metrics/job/some_extra_job
```

## Integration with Prometheus

Prometheus is configured to scrape the Pushgateway automatically at `http://pushgateway:9091/metrics`.

## References

- [Pushgateway Documentation](https://github.com/prometheus/pushgateway)
- [Prometheus Guide](README.prometheus.md)

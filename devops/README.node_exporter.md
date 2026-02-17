# Node Exporter

Node Exporter is a Prometheus exporter for hardware and OS metrics exposed by Unix kernels.

## Quick Start

### 1. Identify Service

Node Exporter is typically run on the host system to monitor hardware. In this stack, it is expected to be available for Prometheus to scrape.

### 2. Prometheus Configuration

Prometheus is configured to scrape Node Exporter at `localhost:9100` (for local runs) or the target host.

## Purpose

It allows you to collect a wide range of metrics from your servers, such as:

- CPU usage
- Memory consumption
- Disk I/O
- Network statistics

These metrics are crucial for monitoring the health and performance of your infrastructure.

## References

- [Node Exporter GitHub](https://github.com/prometheus/node_exporter)
- [Prometheus Guide](README.prometheus.md)

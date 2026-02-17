# OpenTSDB Setup Guide

OpenTSDB is a scalable, distributed Time Series Database (TSDB) built on top of HBase. It is designed to store and serve massive amounts of time series data without losing precision.

## Quick Start

### 1. Start OpenTSDB Container

```bash
cd devops
docker-compose up -d opentsdb
```

> [!NOTE]
> This image (`petergrace/opentsdb-docker`) includes a standalone HBase instance. It may take 30-60 seconds to fully initialize before the API/UI becomes responsive.

### 2. Access Web UI

- **URL**: <http://localhost:4242>

## Basic Operations

### Put Data (HTTP API)

You can send data points to OpenTSDB using the `/api/put` endpoint:

```bash
curl -X POST -H "Content-Type: application/json" \
  http://localhost:4242/api/put \
  -d '{
    "metric": "sys.cpu.user",
    "timestamp": '$(date +%s)',
    "value": 42.5,
    "tags": {
       "host": "web01",
       "dc": "lhr"
    }
  }'
```

### Query Data

Query the last hour of data for a specific metric:

```bash
curl "http://localhost:4242/api/query?start=1h-ago&m=sum:sys.cpu.user"
```

## Configuration

The current setup uses a persistent volume for HBase data:

- **Volume**: `opentsdb_data` (mapped to `/data/hbase` inside the container)

## References

- [OpenTSDB Official Documentation](http://opentsdb.net/docs/build/html/index.html)
- [petergrace/opentsdb-docker (Github)](https://github.com/petergrace/opentsdb-docker)
- [Grafana OpenTSDB Data Source](https://grafana.com/docs/grafana/latest/datasources/opentsdb/)

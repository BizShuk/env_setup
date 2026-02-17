# InfluxDB Setup Guide

InfluxDB is an open-source time series database.

## Quick Start

### 1. Start InfluxDB Container

```bash
cd devops
docker-compose up -d influxdb
```

### 2. Access Web UI

- **URL**: <http://localhost:8086>
- **Initial Setup**:
  - **Username**: `admin`
  - **Password**: `adminpassword`
  - **Organization**: `inf`
  - **Bucket**: `default`

## API Tokens

To connect application or data sources (like Grafana):

1. Log in to InfluxDB UI.
2. Go to **Data** -> **API Tokens**.
3. Generate a new token (e.g., "All Access Token").

## Useful Queries (Flux)

```flux
# Get all measurements
import "influxdata/influxdb/schema"
schema.measurements(bucket: "default")

# Query specific data
from(bucket: "default")
  |> range(start: -1h)
  |> filter(fn: (r) => r._measurement == "cpu")
  |> filter(fn: (r) => r._field == "usage_idle")

# Sample data limit
from(bucket: "default")
  |> range(start: -1h)
  |> limit(n: 10)
```

## References

- [InfluxDB Documentation](https://docs.influxdata.com/influxdb/v2.7/)
- [Grafana Integration](README.grafana.md)

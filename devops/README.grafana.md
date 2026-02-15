# Grafana Setup Guide

This guide explains how to set up Prometheus and InfluxDB as data sources in Grafana for the Inf Stack.

## Access Grafana

1. **URL**: <https://localhost:3000>
2. **Default Credentials**:
   - Username: `admin`
   - Password: `admin`
   - You'll be prompted to change the password on first login

> **Note**: Grafana is configured with a self-signed certificate. Your browser will show a security warning. You can safely "Accept the Risk" or "Proceed" for local development.

## Adding Prometheus as a Data Source

### Method 1: Via Web UI

1. Log in to Grafana at <https://localhost:3000>
2. Click on **☰ Menu** (hamburger icon) → **Connections** → **Data sources**
3. Click **Add data source**
4. Select **Prometheus**
5. Configure the following settings:
   - **Name**: `Prometheus`
   - **URL**: `http://prometheus:9090`
     - Note: Use the container name `prometheus` since they're on the same Docker network (`inf_network`)
   - **Access**: `Server (default)`
6. Click **Save & Test** at the bottom
7. You should see a green success message: "Successfully queried the Prometheus API"

### Method 2: Via Configuration File (Automated)

Create a provisioning file to automatically add Prometheus as a data source:

1. Create the directory structure:

   ```bash
   mkdir -p /Users/shuk/projects/env_setup/inf/grafana/provisioning/datasources
   ```

2. Create the datasource configuration file:

   ```yaml
   # File: /Users/shuk/projects/env_setup/inf/grafana/provisioning/datasources/datasources.yaml
   apiVersion: 1

   datasources:
     - name: Prometheus
       type: prometheus
       access: proxy
       url: http://prometheus:9090
       isDefault: true
       editable: true
   ```

3. Update docker-compose.yaml to mount this directory:

   ```yaml
   grafana:
     # ... existing config ...
     volumes:
       - grafana_data:/var/lib/grafana
       - ./grafana/provisioning:/etc/grafana/provisioning:ro
   ```

## Adding InfluxDB as a Data Source

### Method 1: Via Web UI

1. Log in to Grafana at <https://localhost:3000>
2. Click on **☰ Menu** → **Connections** → **Data sources**
3. Click **Add data source**
4. Select **InfluxDB**
5. Configure the following settings:
   - **Name**: `InfluxDB`
   - **Query Language**: Select `Flux` (for InfluxDB 2.x)
   - **URL**: `http://influxdb:8086`
     - Note: Use the container name `influxdb` since they're on the same Docker network
   - **Access**: `Server (default)`
   - **Auth**: Disable all auth options
   - **InfluxDB Details**:
     - **Organization**: `inf` (as configured in docker-compose.yaml)
     - **Token**: You need to generate this from InfluxDB UI
     - **Default Bucket**: `default`

6. **Getting the InfluxDB Token**:
   - Open InfluxDB UI at <http://localhost:8086>
   - Login with:
     - Username: `admin`
     - Password: `adminpassword`
   - Go to **Data** → **API Tokens** (or click the API Tokens icon in the left sidebar)
   - Click **Generate API Token** → **All Access Token**
   - Give it a description (e.g., "Grafana Access")
   - Copy the generated token
   - Paste it into Grafana's **Token** field

7. Click **Save & Test**
8. You should see a green success message

### Method 2: Via Configuration File (Automated)

Add InfluxDB to the provisioning file:

```yaml
# File: /Users/shuk/projects/env_setup/inf/grafana/provisioning/datasources/datasources.yaml
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: true

  - name: InfluxDB
    type: influxdb
    access: proxy
    url: http://influxdb:8086
    jsonData:
      version: Flux
      organization: inf
      defaultBucket: default
      tlsSkipVerify: true
    secureJsonData:
      token: YOUR_INFLUXDB_TOKEN_HERE
    editable: true
```

**Note**: You'll need to replace `YOUR_INFLUXDB_TOKEN_HERE` with an actual token from InfluxDB.

## Verifying Data Sources

### Test Prometheus

1. In Grafana, go to **Explore** (compass icon in left sidebar)
2. Select **Prometheus** from the data source dropdown
3. Try a simple query: `up`
4. Click **Run query**
5. You should see metrics showing which services are up

### Test InfluxDB

1. In Grafana, go to **Explore**
2. Select **InfluxDB** from the data source dropdown
3. Switch to **Script Editor** mode
4. Try a simple Flux query:

   ```flux
   from(bucket: "default")
     |> range(start: -1h)
     |> limit(n: 10)
   ```

5. Click **Run query**
6. You should see data if any exists in the bucket

## Creating Dashboards

### Import Pre-built Dashboards

Grafana has thousands of community dashboards:

1. Go to **Dashboards** → **Import**
2. Enter a dashboard ID or upload JSON:
   - **Node Exporter Full**: ID `1860` (for Prometheus node metrics)
   - **Prometheus Stats**: ID `2` (for Prometheus itself)
   - **InfluxDB 2.x**: ID `12619` (for InfluxDB metrics)
3. Select your data source
4. Click **Import**

### Create Custom Dashboard

1. Click **+** → **Dashboard**
2. Click **Add visualization**
3. Select your data source (Prometheus or InfluxDB)
4. Build your query
5. Customize the visualization
6. Click **Apply**
7. Save the dashboard

## Useful Prometheus Queries

```promql
# CPU usage
rate(node_cpu_seconds_total{mode="idle"}[5m])

# Memory usage
node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes * 100

# Disk usage
node_filesystem_avail_bytes{mountpoint="/"}

# Network traffic
rate(node_network_receive_bytes_total[5m])
```

## Useful InfluxDB Flux Queries

```flux
# Get all measurements
import "influxdata/influxdb/schema"
schema.measurements(bucket: "default")

# Query specific data
from(bucket: "default")
  |> range(start: -1h)
  |> filter(fn: (r) => r._measurement == "cpu")
  |> filter(fn: (r) => r._field == "usage_idle")
```

## Troubleshooting

### Connection Issues

- **Error: "Bad Gateway"**: Check if the service is running:

  ```bash
  docker ps | grep -E "prometheus|influxdb|grafana"
  ```

- **Error: "Connection refused"**: Verify the URL uses the container name, not `localhost`:
  - ✅ Correct: `http://prometheus:9090`
  - ❌ Wrong: `http://localhost:9090`

### InfluxDB Token Issues

- If the token doesn't work, regenerate it in InfluxDB UI
- Make sure you're using an "All Access Token" or a token with read permissions for the bucket

### Network Issues

- All services must be on the same Docker network (`inf_network`)
- Verify with: `docker network inspect inf_inf_network`

## Next Steps

1. ✅ Add Prometheus data source
2. ✅ Add InfluxDB data source
3. 📊 Import pre-built dashboards
4. 🎨 Create custom dashboards for your metrics
5. 🔔 Set up alerts (Grafana Alerting)

## References

- [Grafana Documentation](https://grafana.com/docs/grafana/latest/)
- [Prometheus Data Source](https://grafana.com/docs/grafana/latest/datasources/prometheus/)
- [InfluxDB Data Source](https://grafana.com/docs/grafana/latest/datasources/influxdb/)
- [Dashboard Gallery](https://grafana.com/grafana/dashboards/)

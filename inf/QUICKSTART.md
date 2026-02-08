# Quick Start: Grafana with Prometheus & InfluxDB

## 🚀 Quick Access

Once the containers are running:

- **Grafana**: <https://localhost:3000> (Accept self-signed cert warning)
  - Username: `admin`
  - Password: `admin`
- **Prometheus**: <http://localhost:9090>
- **InfluxDB**: <http://localhost:8086>
  - Username: `admin`
  - Password: `adminpassword`

## ✅ Automatic Setup (Recommended)

Prometheus is **automatically configured** as a data source! Just log in to Grafana and it's ready to use.

For InfluxDB, you need to add the token manually:

### Step 1: Get InfluxDB Token

```bash
# Open InfluxDB UI
open http://localhost:8086
```

1. Login with `admin` / `adminpassword`
2. Click **Data** → **API Tokens**
3. Click **Generate API Token** → **All Access Token**
4. Copy the token

### Step 2: Add Token to Grafana

```bash
# Open Grafana UI
open http://localhost:3000
```

1. Login with `admin` / `admin`
2. Go to **☰ Menu** → **Connections** → **Data sources**
3. Click on **InfluxDB** (it should already be listed)
4. Paste your token in the **Token** field
5. Click **Save & Test**

## 📊 Quick Test

### Test Prometheus

1. In Grafana, click **Explore** (compass icon)
2. Select **Prometheus**
3. Enter query: `up`
4. Click **Run query**
5. You should see which services are running

### Import a Dashboard

1. Go to **Dashboards** → **Import**
2. Enter dashboard ID: `2` (Prometheus Stats)
3. Select **Prometheus** as data source
4. Click **Import**

## 🔧 Manual Setup (Alternative)

If you prefer to add data sources manually, see [GRAFANA_SETUP.md](GRAFANA_SETUP.md) for detailed instructions.

## 📝 Useful Commands

```bash
# Check container status
docker ps | grep -E "grafana|prometheus|influxdb"

# View Grafana logs
docker logs grafana

# Restart Grafana
docker restart grafana

# Restart all services
cd /Users/shuk/projects/env_setup/inf
docker-compose restart
```

## 🎯 Next Steps

1. ✅ Access Grafana at <http://localhost:3000>
2. ✅ Verify Prometheus data source works
3. 🔑 Add InfluxDB token
4. 📊 Import pre-built dashboards
5. 🎨 Create custom dashboards

For detailed setup instructions, see [GRAFANA_SETUP.md](GRAFANA_SETUP.md)

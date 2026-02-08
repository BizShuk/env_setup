# test DNS Setup for Docker Containers

This setup enables automatic hostname resolution from macOS host to Docker containers using the `.test` domain.

## Quick Start

### 1. Start CoreDNS Container

```bash
cd inf
docker-compose up -d coredns
```

### 2. Configure macOS Resolver

```bash
./bin/setup_local_dns
```

This will configure macOS to route all `.test` domain queries to the CoreDNS container.

### 3. Verify DNS Resolution

```bash
# Test CoreDNS directly on port 10053
dig @127.0.0.1 -p 10053 grafana.test

# Test via macOS resolver (should resolve automatically)
nslookup grafana.test
```

### 4. Access Services by Hostname

You can now access your Docker services using friendly hostnames:

- Grafana: `https://grafana.test:3000`
- Prometheus: `http://prometheus.test:9090`
- MySQL: `mysql.test:3306`
- InfluxDB: `http://influxdb.test:8086`

## How It Works

1. **CoreDNS Container**: Runs on port 10053 on the host (internal 53) to avoid macOS port 53 conflicts.
2. **Wildcard Template**: Any `*.test` domain resolves to `127.0.0.1`.
3. **macOS Resolver**: `/etc/resolver/test` routes `.test` queries to `127.0.0.1:10053`.
4. **Port Forwarding**: Docker maps container ports to localhost.

## Troubleshooting

### DNS Not Resolving

```bash
# Check if CoreDNS is running
docker ps | grep coredns

# Check CoreDNS logs
docker logs coredns

# Verify resolver configuration
cat /etc/resolver/test
```

### Port 10053 Conflict

CoreDNS is configured to use port 10053 on the host to avoid conflicts with `mDNSResponder` or `limactl` which often occupy port 53.

```bash
# Find what's using port 10053
sudo lsof -i :10053
```

### Regular DNS Still Works

The `.test` resolver only affects `.test` domains. All other domains (like `google.com`) continue to use your system DNS.

## Rollback

To remove the test DNS setup:

```bash
# Remove macOS resolver
sudo rm /etc/resolver/test

# Stop CoreDNS container
docker stop coredns
```

## References

- Spec: [specs/002-test-dns/spec.md](../specs/002-test-dns/spec.md)
- Plan: [specs/002-test-dns/plan.md](../specs/002-test-dns/plan.md)
- Research: [specs/002-test-dns/research.md](../specs/002-test-dns/research.md)

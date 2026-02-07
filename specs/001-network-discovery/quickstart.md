# Quickstart: Network Discovery Command

## Installation

```bash
go build -o network-discovery cmd/network-discovery/main.go
```

## Usage

### Basic Scan (Fast Mode)
Scans the current local subnet for active hosts and top 1000 ports.
```bash
sudo ./network-discovery --mode fast
```

### Thorough Scan
Scans all reachable internal subnets and performs OS fingerprinting.
```bash
sudo ./network-discovery --mode thorough
```

### JSON Export
Export results to a file for automation.
```bash
sudo ./network-discovery --output results.json --format json
```

## Requirements
- **Privileges**: Requires `sudo` for raw ARP and ICMP packets.
- **Operating System**: macOS (Darwin) or Linux.
- **Go**: Version 1.25.4+ (see `cmd/go.mod`).

## Common Commands
- `list-interfaces`: List all detectable network interfaces.
- `scan [interface]`: Scan a specific interface.

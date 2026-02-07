# Data Model: Network Discovery

## Entities

### ScanResult
The root object containing all discovery data for a session.
- `timestamp`: RFC3339 string (Start of scan)
- `duration_seconds`: Float (Total execution time)
- `interfaces`: List of `NetworkInterface` objects
- `hosts`: List of `Host` objects

### Host
Represents a discovered device.
- `ip`: String (IPv4 address)
- `mac`: String (MAC address, e.g., "00:00:00:00:00:00")
- `hostname`: String (Resolved hostname or empty)
- `manufacturer`: String (Best effort from ARP cache)
- `os_guess`: String (Heuristic based on TTL)
- `services`: List of `Service` objects
- `status`: String ("online", "offline")

### Service
Represents a listening port.
- `port`: Integer (1-65535)
- `protocol`: String ("tcp", "udp")
- `name`: String (Common name, e.g., "ssh")
- `banner`: String (Captured banner text)
- `state`: String ("open", "closed", "filtered")

### NetworkInterface
Represents the scanning hardware.
- `name`: String (e.g., "en0")
- `ip`: String (Local IP)
- `subnet`: String (CIDR notation, e.g., "192.168.1.0/24")
- `gateway`: String (Default gateway IP)

## Relationships
- **ScanResult** HAS MANY **Hosts**
- **Host** HAS MANY **Services**
- **ScanResult** references **NetworkInterface** used for discovery.

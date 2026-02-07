# Research: Network Discovery Implementation

## Protocol Selection

### Host Discovery
- **ARP (Primary for Local)**: Use `github.com/mdlayher/arp`. It provides a clean API for sending ARP requests and parsing responses. Most reliable for the local link.
- **ICMP (Secondary)**: Use `golang.org/x/net/icmp`. Standard for detecting hosts that might block ARP but respond to pings.
- **TCP SYN Ping**: Attempting connections to common ports (80, 443, 22) as a fallback discovery method.

### Name Resolution
- **mDNS**: Use `github.com/hashicorp/mdns`. Best for modern local networks (macOS, Linux, IoT).
- **DNS**: Standard `net.LookupAddr` for reverse DNS lookups.
- **NetBIOS**: Low priority; will only implement if time permits or explicitly requested.

### Identification
- **OUI (MAC Manufacturer)**: Will be based on local ARP cache as per clarified spec.
- **OS Guessing**: Use TTL (Time-To-Live) analysis from ICMP or TCP responses:
    - 64: Linux/Unix/macOS
    - 128: Windows
    - 255: Network devices (Routers/Switches)
- **Service Versioning**: Connect to port, read first 1024 bytes (Banner Grabbing).

## Technical Decisions

### Decision: Aggressive Concurrency
- **Rationale**: To meet the <15s target for /24 subnets (254 hosts * 1000 ports = 254k checks).
- **Implementation**: Go routines with a `sync.WaitGroup` or a worker pool. Given the aggressive requirement, we will use a high-concurrency worker pool (e.g., `ants` or raw channels).
- **Alternatives**: Sequential (too slow), one-goroutine-per-check (OS resource exhaustion).

### Decision: Native Packet Handling
- **Rationale**: `mdlayher/arp` is pure Go and doesn't require `libpcap` C-bindings, making cross-compilation and deployment easier.
- **Implementation**: Bind to raw sockets.

## Best Practices
- **Timeouts**: Every scan operation must have a strict context-based timeout.
- **Privileges**: Detect if running as root/sudo early and provide a clear error message if not.
- **Rate Limiting**: Although aggressive, include a jitter or small delay to avoid triggering "SYN Flood" protections on sensitive hardware.

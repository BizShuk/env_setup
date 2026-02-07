# Feature Specification: Network Discovery Command

**Feature Branch**: `001-network-discovery`  
**Created**: Saturday, February 7, 2026  
**Status**: Draft  
**Input**: User description: "create a command can know local network as much as possible"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Identify Active Devices (Priority: P1)

As a network administrator or security-conscious user, I want to quickly see all active devices currently connected to my local network so that I can maintain visibility of what is on my network.

**Why this priority**: This is the core functionality. Without knowing which devices exist, further discovery is impossible. It provides immediate value by identifying all connected hardware.

**Independent Test**: Can be fully tested by running the command on a known network and verifying that the number of reported IP/MAC addresses matches the known active devices.

**Acceptance Scenarios**:

1. **Given** a local network with 5 active devices, **When** I run the discovery command, **Then** it should list at least those 5 devices with their IP and MAC addresses.
2. **Given** no network connection, **When** I run the discovery command, **Then** it should provide a clear error message indicating that no network interface is available.

---

### User Story 2 - Discover Open Services (Priority: P2)

As a developer or system integrator, I want to know which ports and services are open on discovered devices so that I can understand the network's attack surface or available resources.

**Why this priority**: This adds depth to the discovery. Knowing a device exists is useful, but knowing it's running a web server or an SSH service is critical for "knowing the network as much as possible."

**Independent Test**: Can be tested by running a known service (e.g., a local web server on port 8080) and verifying the command identifies that port as "open" on the localhost or target IP.

**Acceptance Scenarios**:

1. **Given** a device with an open HTTP service on port 80, **When** I run a deep scan, **Then** the command should identify port 80 as open and label it as "HTTP".
2. **Given** a device with all ports firewalled, **When** I run a deep scan, **Then** the command should correctly report no open ports for that specific host.

---

### User Story 3 - Identify Device Types & OS (Priority: P3)

As a network auditor, I want the system to guess the operating system and device type (e.g., Router, Printer, Mobile, Linux/Windows) so that I can categorize the devices on my network without manual inspection.

**Why this priority**: This fulfills the "as much as possible" requirement by providing context beyond just networking data.

**Independent Test**: Can be tested by scanning a known device (e.g., a MacBook or a Raspberry Pi) and verifying the OS guess reasonably matches the actual device type.

**Acceptance Scenarios**:

1. **Given** a known Linux-based router, **When** I run the identification scan, **Then** the command should attempt to classify the device as a "Router" or "Network Device".
2. **Given** an unknown device with minimal fingerprints, **When** I run the identification scan, **Then** it should gracefully label the OS/Type as "Unknown" rather than failing.

---

### Edge Cases

- **Subnet Boundaries**: How does the command handle networks larger than a /24 (e.g., a /16 corporate network)? [Assumption: It should default to the current subnet but allow manual range specification].
- **Hidden Devices**: What happens when a device is configured to ignore ICMP (ping) requests? [Assumption: The command should attempt ARP discovery or TCP SYN scanning to detect "stealth" devices].
- **Network Congestion**: How does the command behave on a high-latency or low-bandwidth network? [Assumption: It should have configurable timeouts and retry logic to avoid missing devices].

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST automatically detect and scan all active local network interfaces and their associated IP ranges/subnets sequentially.
- **FR-002**: System MUST discover active hosts using multiple methods (ICMP Echo, ARP requests, and TCP SYN pings).
- **FR-003**: System MUST perform a port scan of the top 1000 most common ports on discovered hosts.
- **FR-004**: System MUST attempt to resolve hostnames via DNS, NetBIOS, or mDNS.
- **FR-005**: System MUST provide a "fast" vs "thorough" mode:
  - **Fast Mode**: Discovery is restricted to the current local subnets only.
  - **Thorough Mode**: System attempts to identify and scan all reachable internal subnets and VLANs.
- **FR-006**: System MUST export discovery results in a structured JSON format for machine readability.
- **FR-007**: System MUST handle permission-related errors (e.g., requiring root/sudo for raw sockets) with clear user instructions.
- **FR-008**: System MUST present discovery results in a formatted tabular view in the terminal by default, showing Hostname, IP, and a summary of Open Ports.
- **FR-009**: System MUST utilize an aggressive concurrency model, spawning as many parallel workers as allowed by the operating system to maximize scanning speed.
- **FR-010**: System MUST attempt to perform banner grabbing on open ports to identify service versions and application names.

## Clarifications

### Session 2026-02-07
- Q: How should the command present data in the terminal by default for a human user? → A: Tabular (formatted table with Host, IP, and Open Ports).
- Q: To scan 1000 ports across potentially 254 hosts in under 15 seconds, how should the tool handle concurrency? → A: Aggressive (spawn maximum parallel workers for speed).
- Q: For discovered open ports, how deep should the service identification go? → A: Banner Grabbing (Connect and read the initial response to identify versions).
- Q: How should the tool translate MAC addresses into manufacturer names (OUI lookup)? → A: Skip/Optional (Only show manufacturers if the OS already knows them in the ARP cache).
- Q: If the system has multiple active network interfaces, how should the tool decide which one to scan? → A: All (Scan all active local interfaces sequentially).

### Key Entities

- **Host**: Represents a single device on the network. Attributes: IP Address, MAC Address, Hostname, Manufacturer (OUI - optional/best effort from OS), OS Guess.
- **Service**: Represents a listening port on a host. Attributes: Port Number, Protocol (TCP/UDP), Service Name (e.g., SSH, HTTP), Version (if detectable).
- **Network Interface**: The local hardware used for scanning. Attributes: Name, IP, Subnet Mask, Gateway.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can perform a basic host discovery of a standard home network (/24) in under 15 seconds per interface.
- **SC-002**: The command accurately identifies 100% of devices that respond to ARP or ICMP on the local subnet.
- **SC-003**: 90% of common services (SSH, HTTP, HTTPS, SMB, Telnet) are correctly identified on active ports.
- **SC-004**: The JSON export contains all mandatory fields (IP, MAC, Hostname) for every discovered device.

## Assumptions

- The user has administrative privileges (sudo) if the implementation requires raw sockets for ARP/ICMP.
- The command is executed from a device with a valid local IP address on the target network.
- "Local network" is defined as the primary subnet(s) the executing device is currently connected to.

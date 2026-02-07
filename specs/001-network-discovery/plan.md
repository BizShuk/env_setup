# Implementation Plan: Network Discovery Command

**Branch**: `001-network-discovery` | **Date**: Saturday, February 7, 2026 | **Spec**: [/specs/001-network-discovery/spec.md]
**Input**: Feature specification from `/specs/001-network-discovery/spec.md`

## Summary

Implement a Go-based CLI tool that autonomously discovers active hosts and services across all local network interfaces. The tool will utilize aggressive concurrency and multiple discovery protocols (ARP, ICMP, TCP) to meet the 15-second performance target for standard subnets. Key features include service banner grabbing, OS/Device type guessing, and dual-format output (Tabular for humans, JSON for machines).

## Technical Context

**Language/Version**: Go 1.25.4  
**Primary Dependencies**: `github.com/spf13/cobra`, `github.com/sirupsen/logrus`, `net`, `golang.org/x/net/icmp`, `google/gopacket` (for raw ARP/Ethernet) or NEEDS CLARIFICATION  
**Storage**: N/A (JSON File output)  
**Testing**: `go test` with mock network interfaces and local loopback integration tests.  
**Target Platform**: darwin (macOS), linux  
**Project Type**: single (CLI + Library)  
**Performance Goals**: <15s discovery time for a standard /24 subnet per interface.  
**Constraints**: Requires administrative privileges (sudo) for raw socket operations (ARP/ICMP); Aggressive concurrency model.  
**Scale/Scope**: Scanning top 1000 common ports on discovered active hosts.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **Library-First**: Core logic will be implemented in `pkg/discovery` and `pkg/scanner` for reuse.
- [x] **CLI Interface**: Command-line entry point at `cmd/network-discovery`.
- [x] **Test-First**: Implementation will follow TDD for protocol parsers and discovery logic.
- [x] **Observability**: Uses `logrus` for structured logging and provides standard JSON output.
- [x] **Simplicity**: Avoids complex external dependencies unless required for raw packet handling.

## Project Structure

### Documentation (this feature)

```text
specs/001-network-discovery/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (JSON schemas)
└── tasks.md             # Phase 2 output (Future)
```

### Source Code (repository root)

```text
cmd/
└── network-discovery/   # CLI entry point
    └── main.go

pkg/
├── discovery/           # Host discovery (ARP, ICMP)
├── scanner/             # Port scanning & banner grabbing
├── identification/      # OS/Device type guessing
├── output/              # Tabular & JSON formatting
└── network/             # Interface & subnet utilities

internal/                # Private helpers for packet crafting
```

**Structure Decision**: Single project structure following Go standards. CLI layer at `cmd/`, reusable logic in `pkg/`.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| N/A | | |

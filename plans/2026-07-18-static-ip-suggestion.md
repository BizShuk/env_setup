# macOS Static IP Suggestion Implementation Plan

**Goal:** Extend `bin/mac/mac_static_ip.sh status` (including no-argument execution) to display the current network information and a copyable static-IP command selected from the current subnet.

**Architecture:** Keep the existing `networksetup`-only design. Add pure Bash IPv4 conversion, subnet-bound calculation, percentage-band calculation, random host selection, and suggestion rendering inside the existing script; test the observable `status` output with a fake macOS command environment.

**Tech Stack:** Bash, macOS `networksetup`, `/dev/urandom`, shell assertions.

## Global Constraints

- Keep the existing `set`, `dhcp`, and `services` command behavior unchanged.
- Exclude the subnet network and broadcast addresses from candidate hosts.
- Calculate two candidate bands from usable hosts: `25%-50%` and `75%-100%`.
- Select a band with equal probability, then select one host from that band.
- Print the command as `mac_static_ip.sh set ...` without `--yes`.
- Fall back to the current router as DNS when no IPv4 DNS server is configured.
- Do not add dependencies on `ipconfig` or `route`.
- Keep unrelated worktree changes untouched.

### Task 1: Add an observable failing regression test

**Files:**

- Create: `tests/mac_static_ip_test.sh`

The test will place fake `uname` and `networksetup` commands earlier in `PATH`, return a `/24` Wi-Fi configuration, execute the real script with `status`, and assert that output contains both exact candidate ranges, the current DNS servers, a `mac_static_ip.sh set` command, and a selected IP inside one of the two ranges. It must fail against the current script because no recommendation is printed yet.

Run:

```bash
bash tests/mac_static_ip_test.sh
```

Expected before implementation: failure stating that the recommended static-IP output is missing.

### Task 2: Implement subnet math and suggestion output

**Files:**

- Modify: `bin/mac/mac_static_ip.sh`

Add testable Bash functions for IPv4-to-integer conversion, integer-to-IPv4 conversion, network/broadcast calculation, percentage candidate ranges, and random selection from `/dev/urandom`. Parse `IP address`, `Subnet mask`, and `Router` from the existing `networksetup -getinfo` output; parse IPv4 DNS entries from the existing DNS output; render both candidate ranges and one copyable command. For `/31`, `/32`, invalid, or incomplete current configuration, print an explanatory unavailable message and retain the existing status output.

Run:

```bash
bash tests/mac_static_ip_test.sh
bash -n bin/mac/mac_static_ip.sh
```

Expected: the regression test passes and the script has valid Bash syntax.

### Task 3: Update usage documentation and run final verification

**Files:**

- Modify: `README.md`

Document that `status` prints the current information, two recommended IP ranges, and a copyable command, while retaining the DHCP reservation warning.

Run:

```bash
bash -n bin/mac/mac_static_ip.sh tests/mac_static_ip_test.sh
bash tests/mac_static_ip_test.sh
shellcheck -x -P bin/mac bin/mac/mac_static_ip.sh tests/mac_static_ip_test.sh
git diff --check
git status --short
```

The final worktree check must show only the intended files plus any pre-existing unrelated changes. The test harness uses a fake Darwin environment so the real macOS-only gate and live network configuration are never changed during automated tests.

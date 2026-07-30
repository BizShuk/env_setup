# Network Cobra Commands Implementation Plan

> **Execution:** 依 `test-driven-development` 逐項執行，先觀察 failing test，再加入最小 implementation。

**Status:** Completed 2026-07-30

**Goal:** 將 `bin/network/scan_network.sh` 的 `private` 與 `target` modes 拆成
`env_setup network private`、`env_setup network target`，完成後移除 shell runtime。

**Architecture:** `cmd/network` 僅擁有 Cobra command hierarchy；`svc/network` 擁有
CIDR validation、command execution、output parsing 與 topology rendering。External commands
透過 injected `Runner` 執行，tests 不接觸真實 LAN。

**Tech Stack:** Go 1.26、spf13/cobra、gosdk root hook、stdlib `net/netip`

---

## Task 1: Target scan service

**Files:**

- Create: `svc/network/runner.go`
- Create: `svc/network/service.go`
- Create: `svc/network/target.go`
- Test: `svc/network/target_test.go`

1. 先寫 nmap command、grepable output parsing 與 CIDR validation tests。
2. 執行 package test，確認因 implementation 缺失而失敗。
3. 實作 `ScanTarget` 與 bounded `/24` ping fallback。
4. 重跑 package test 至 green。

## Task 2: Private topology service

**Files:**

- Create: `svc/network/private.go`
- Create: `svc/network/parse.go`
- Create: `svc/network/topology.go`
- Test: `svc/network/private_test.go`

1. 先寫 traceroute private-hop、nmap host/service parsing 與 topology output tests。
2. 執行 package test，確認因 implementation 缺失而失敗。
3. 實作 dependency checks、scan orchestration 與 `network.topo` write。
4. 重跑 package test 至 green。

## Task 3: Cobra hierarchy and root wiring

**Files:**

- Create: `cmd/network/network.go`
- Create: `cmd/network/private.go`
- Create: `cmd/network/target.go`
- Test: `cmd/network/network_test.go`
- Modify: `cmd/root.go`
- Modify: `cmd/root_test.go`
- Modify: `cmd/command_file_test.go`

1. 先寫 command paths、defaults、flags 與 one-command-one-file architecture tests。
2. 執行 command tests，確認因 commands 尚未存在而失敗。
3. 實作 commands 並注入 `svc/network.Service`。
4. 重跑 command tests 至 green。

## Task 4: Remove shell adapter and refresh canonical docs

**Files:**

- Delete: `bin/network/scan_network.sh`
- Modify: `README.md`
- Modify: `README.business.md`
- Modify: `CLAUDE.md`
- Modify: `README.todo`
- Modify: `bin/README.md`
- Modify: `docs/bin_index.md`
- Modify: `docs/terminology.md`

1. 以 `env_setup network ...` 取代 current shell usage 與 ownership。
2. 移除空的 `bin/network/` directory。
3. 確認 current docs 不再宣告 shell runtime。

## Task 5: Verification

1. Run `gofmt` on changed Go files.
2. Run `go test ./svc/network ./cmd/network ./cmd ./...`.
3. Run `go vet ./...`.
4. Run `./build.sh`.
5. Run installed binary `network`, `network private --help` 與 `network target --help`。
6. Inspect scoped diff and confirm unrelated dirty files remain untouched.

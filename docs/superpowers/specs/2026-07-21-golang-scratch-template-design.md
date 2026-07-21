# Go + scratch container template

**Date:** 2026-07-21  
**Status:** Approved design  
**Location:** `docker/golang-scratch/`

## Goal

Provide a copy-paste starter for future Go services in this repo: compile a static binary and ship it in a `FROM scratch` image. Not tied to the root `macbackup` module (macOS-only).

## Decisions

| Decision | Choice |
| -------- | ------ |
| Purpose | Reusable service template |
| Path | `docker/golang-scratch/` (alongside `awesome-compose`) |
| Sample apps | HTTP server + CLI via separate `cmd/` packages |
| Binary selection | Dockerfile `TARGET` build-arg (`server` \| `cli`) |
| Hardening | Minimal v1; README notes certs / non-root for later |

## Layout

```text
docker/golang-scratch/
├── README.md
├── compose.yaml          # builds/runs server on :8080
├── Dockerfile            # multi-stage; TARGET=server|cli
├── go.mod                # standalone module
├── cmd/
│   ├── server/main.go    # HTTP :8080 — GET / and GET /healthz
│   └── cli/main.go       # print hello/version, exit 0
└── internal/
    └── version/version.go
```

## Build & run

### Dockerfile

1. **builder** — `golang:1.26` (align with repo Go toolchain), `CGO_ENABLED=0`, build `./cmd/${TARGET}` → `/out/app`
2. **runtime** — `FROM scratch`, copy `/out/app` → `/app`, `ENTRYPOINT ["/app"]`
3. Default `TARGET=server`

### Commands

```bash
# Server (compose)
docker compose up --build

# CLI image
docker build --build-arg TARGET=cli -t golang-scratch:cli .
docker run --rm golang-scratch:cli
```

### Server behavior

- Listen on `:8080`
- `GET /` → short hello body
- `GET /healthz` → `ok`

## Success criteria

- `docker compose up --build` serves `/` and `/healthz`
- `TARGET=cli` image prints one line and exits 0
- Runtime is scratch (no shell inside the image)

## Out of scope (v1)

- CA certificates / timezone data in the image
- Non-root `USER`
- CI workflows
- Multi-arch image publish
- Integration with root `macbackup`, `run.sh`, or `ecosystem.config.js`

README may document how to add certs / non-root later without implementing them in v1.

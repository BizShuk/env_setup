# Go + scratch container template Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a copy-paste Go service starter at `docker/golang-scratch/` that builds a static binary into a `FROM scratch` image, with `cmd/server` and `cmd/cli` selected via Dockerfile `TARGET`.

**Architecture:** Standalone Go module under `docker/golang-scratch/`. Shared `internal/version` package. Two entrypoints in `cmd/`. Multi-stage Dockerfile: `golang:1.26` builder → `scratch` runtime. `compose.yaml` runs the server on `:8080`.

**Tech Stack:** Go 1.26, Docker (BuildKit), Docker Compose, `net/http`, standard library only.

## Global Constraints

- Path: `docker/golang-scratch/` only (do not modify root `macbackup` / `go.mod`)
- Go image: `golang:1.26`
- Runtime base: `FROM scratch`
- Binary selection: build-arg `TARGET` = `server` | `cli` (default `server`)
- Static build: `CGO_ENABLED=0`
- Server: listen `:8080`; `GET /` hello; `GET /healthz` → `ok`
- No CA certs, non-root, CI, or multi-arch in v1
- Spec: `docs/superpowers/specs/2026-07-21-golang-scratch-template-design.md`

---

## File map

| File | Responsibility |
| ---- | -------------- |
| `docker/golang-scratch/go.mod` | Module `golang-scratch`, `go 1.26` |
| `docker/golang-scratch/internal/version/version.go` | `Version` string + `String()` |
| `docker/golang-scratch/internal/version/version_test.go` | Unit test for version string |
| `docker/golang-scratch/internal/server/handlers.go` | HTTP handlers for `/` and `/healthz` |
| `docker/golang-scratch/internal/server/handlers_test.go` | Handler tests via `httptest` |
| `docker/golang-scratch/cmd/cli/main.go` | Print version line, exit 0 |
| `docker/golang-scratch/cmd/server/main.go` | Wire handlers, listen `:8080` |
| `docker/golang-scratch/Dockerfile` | Multi-stage build; `TARGET` selects `cmd/*` |
| `docker/golang-scratch/compose.yaml` | Build/run server, publish `8080` |
| `docker/golang-scratch/README.md` | Build/run + optional hardening notes |

---

### Task 1: Module + version package

**Files:**
- Create: `docker/golang-scratch/go.mod`
- Create: `docker/golang-scratch/internal/version/version.go`
- Create: `docker/golang-scratch/internal/version/version_test.go`

**Interfaces:**
- Consumes: nothing
- Produces: `package version` with `const Version = "0.1.0"` and `func String() string` returning `"golang-scratch " + Version`

- [ ] **Step 1: Create module directory and `go.mod`**

```bash
mkdir -p docker/golang-scratch/internal/version
cd docker/golang-scratch
go mod init golang-scratch
```

Expected `go.mod`:

```go
module golang-scratch

go 1.26
```

If `go mod init` writes a different Go version, edit `go.mod` so the directive is exactly `go 1.26`.

- [ ] **Step 2: Write the failing version test**

Create `docker/golang-scratch/internal/version/version_test.go`:

```go
package version_test

import (
	"strings"
	"testing"

	"golang-scratch/internal/version"
)

func TestStringContainsVersion(t *testing.T) {
	got := version.String()
	if !strings.Contains(got, version.Version) {
		t.Fatalf("String() = %q, want substring %q", got, version.Version)
	}
	if !strings.HasPrefix(got, "golang-scratch ") {
		t.Fatalf("String() = %q, want prefix %q", got, "golang-scratch ")
	}
}
```

- [ ] **Step 3: Run test to verify it fails**

```bash
cd docker/golang-scratch
go test ./internal/version/
```

Expected: FAIL (package or `String` / `Version` undefined)

- [ ] **Step 4: Implement version package**

Create `docker/golang-scratch/internal/version/version.go`:

```go
package version

const Version = "0.1.0"

func String() string {
	return "golang-scratch " + Version
}
```

- [ ] **Step 5: Run test to verify it passes**

```bash
cd docker/golang-scratch
go test ./internal/version/
```

Expected: PASS (`ok`)

- [ ] **Step 6: Commit** (only if the user asked to commit)

```bash
git add docker/golang-scratch/go.mod \
  docker/golang-scratch/internal/version/version.go \
  docker/golang-scratch/internal/version/version_test.go
git commit -m "$(cat <<'EOF'
feat(docker): add golang-scratch version package

EOF
)"
```

---

### Task 2: HTTP handlers

**Files:**
- Create: `docker/golang-scratch/internal/server/handlers.go`
- Create: `docker/golang-scratch/internal/server/handlers_test.go`

**Interfaces:**
- Consumes: `version.String()` from Task 1
- Produces: `package server` with:
  - `func NewMux() *http.ServeMux` — registers `GET /` and `GET /healthz`
  - `func Hello(w http.ResponseWriter, r *http.Request)` — writes `version.String() + "\n"`
  - `func Healthz(w http.ResponseWriter, r *http.Request)` — writes `"ok\n"`

- [ ] **Step 1: Write failing handler tests**

```bash
mkdir -p docker/golang-scratch/internal/server
```

Create `docker/golang-scratch/internal/server/handlers_test.go`:

```go
package server_test

import (
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"golang-scratch/internal/server"
	"golang-scratch/internal/version"
)

func TestHealthz(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/healthz", nil)
	rr := httptest.NewRecorder()
	server.NewMux().ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d", rr.Code, http.StatusOK)
	}
	body, _ := io.ReadAll(rr.Body)
	if strings.TrimSpace(string(body)) != "ok" {
		t.Fatalf("body = %q, want %q", body, "ok")
	}
}

func TestHello(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/", nil)
	rr := httptest.NewRecorder()
	server.NewMux().ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d", rr.Code, http.StatusOK)
	}
	body, _ := io.ReadAll(rr.Body)
	got := strings.TrimSpace(string(body))
	if got != version.String() {
		t.Fatalf("body = %q, want %q", got, version.String())
	}
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd docker/golang-scratch
go test ./internal/server/
```

Expected: FAIL (`server` package / symbols undefined)

- [ ] **Step 3: Implement handlers**

Create `docker/golang-scratch/internal/server/handlers.go`:

```go
package server

import (
	"net/http"

	"golang-scratch/internal/version"
)

func NewMux() *http.ServeMux {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /", Hello)
	mux.HandleFunc("GET /healthz", Healthz)
	return mux
}

func Hello(w http.ResponseWriter, r *http.Request) {
	_, _ = w.Write([]byte(version.String() + "\n"))
}

func Healthz(w http.ResponseWriter, r *http.Request) {
	_, _ = w.Write([]byte("ok\n"))
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd docker/golang-scratch
go test ./...
```

Expected: all packages PASS

- [ ] **Step 5: Commit** (only if the user asked to commit)

```bash
git add docker/golang-scratch/internal/server/
git commit -m "$(cat <<'EOF'
feat(docker): add golang-scratch HTTP handlers

EOF
)"
```

---

### Task 3: CLI and server entrypoints

**Files:**
- Create: `docker/golang-scratch/cmd/cli/main.go`
- Create: `docker/golang-scratch/cmd/server/main.go`

**Interfaces:**
- Consumes: `version.String()`, `server.NewMux()`
- Produces: two `main` packages:
  - `cmd/cli` — prints `version.String()` to stdout, exits 0
  - `cmd/server` — `http.ListenAndServe(":8080", server.NewMux())`; on listen error, print to stderr and `os.Exit(1)`

- [ ] **Step 1: Create CLI main**

```bash
mkdir -p docker/golang-scratch/cmd/cli docker/golang-scratch/cmd/server
```

Create `docker/golang-scratch/cmd/cli/main.go`:

```go
package main

import (
	"fmt"

	"golang-scratch/internal/version"
)

func main() {
	fmt.Println(version.String())
}
```

- [ ] **Step 2: Create server main**

Create `docker/golang-scratch/cmd/server/main.go`:

```go
package main

import (
	"fmt"
	"net/http"
	"os"

	"golang-scratch/internal/server"
)

func main() {
	addr := ":8080"
	fmt.Fprintf(os.Stderr, "listening on %s\n", addr)
	if err := http.ListenAndServe(addr, server.NewMux()); err != nil {
		fmt.Fprintf(os.Stderr, "listen: %v\n", err)
		os.Exit(1)
	}
}
```

- [ ] **Step 3: Build both binaries locally**

```bash
cd docker/golang-scratch
go build -o /tmp/golang-scratch-cli ./cmd/cli
go build -o /tmp/golang-scratch-server ./cmd/server
/tmp/golang-scratch-cli
```

Expected CLI output: `golang-scratch 0.1.0`

- [ ] **Step 4: Smoke-test server with timeout**

```bash
cd docker/golang-scratch
/tmp/golang-scratch-server &
pid=$!
sleep 0.5
curl -sf http://127.0.0.1:8080/
echo
curl -sf http://127.0.0.1:8080/healthz
echo
kill "$pid"
```

Expected:

```text
golang-scratch 0.1.0
ok
```

- [ ] **Step 5: Commit** (only if the user asked to commit)

```bash
git add docker/golang-scratch/cmd/
git commit -m "$(cat <<'EOF'
feat(docker): add golang-scratch cmd/server and cmd/cli

EOF
)"
```

---

### Task 4: Dockerfile, compose, README

**Files:**
- Create: `docker/golang-scratch/Dockerfile`
- Create: `docker/golang-scratch/compose.yaml`
- Create: `docker/golang-scratch/README.md`

**Interfaces:**
- Consumes: `cmd/server`, `cmd/cli` from Task 3
- Produces: scratch image with `ENTRYPOINT ["/app"]`; compose service `app` on host port `8080`

- [ ] **Step 1: Write Dockerfile**

Create `docker/golang-scratch/Dockerfile`:

```dockerfile
# syntax=docker/dockerfile:1

ARG TARGET=server

FROM golang:1.26 AS builder
ARG TARGET
WORKDIR /src
ENV CGO_ENABLED=0
COPY go.mod ./
COPY . .
RUN test "$TARGET" = "server" -o "$TARGET" = "cli"
RUN go build -trimpath -ldflags="-s -w" -o /out/app ./cmd/${TARGET}

FROM scratch
COPY --from=builder /out/app /app
ENTRYPOINT ["/app"]
```

- [ ] **Step 2: Write compose.yaml**

Create `docker/golang-scratch/compose.yaml`:

```yaml
services:
  app:
    build:
      context: .
      args:
        TARGET: server
    ports:
      - "8080:8080"
```

- [ ] **Step 3: Write README.md**

Create `docker/golang-scratch/README.md`:

```markdown
# golang-scratch

Copy-paste starter: static Go binary in a `FROM scratch` image.

## Layout

- `cmd/server` — HTTP on `:8080` (`/` and `/healthz`)
- `cmd/cli` — print version and exit
- Dockerfile `TARGET` build-arg selects which binary (`server` default, or `cli`)

## Run server

```bash
docker compose up --build
curl http://127.0.0.1:8080/
curl http://127.0.0.1:8080/healthz
```

## Run CLI image

```bash
docker build --build-arg TARGET=cli -t golang-scratch:cli .
docker run --rm golang-scratch:cli
```

## Local Go (no Docker)

```bash
go test ./...
go run ./cmd/server
go run ./cmd/cli
```

## Optional hardening (not in this image)

`scratch` has no CA certs, timezone data, or shell. For HTTPS clients or non-root, copy certs from an alpine stage and set `USER` — add those only when a real service needs them.
```

- [ ] **Step 4: Build and run server via compose**

```bash
cd docker/golang-scratch
docker compose up --build -d
curl -sf http://127.0.0.1:8080/
echo
curl -sf http://127.0.0.1:8080/healthz
echo
docker compose down
```

Expected bodies: `golang-scratch 0.1.0` and `ok`

- [ ] **Step 5: Build and run CLI image**

```bash
cd docker/golang-scratch
docker build --build-arg TARGET=cli -t golang-scratch:cli .
docker run --rm golang-scratch:cli
```

Expected: `golang-scratch 0.1.0`

- [ ] **Step 6: Confirm scratch has no shell**

```bash
docker run --rm --entrypoint /bin/sh golang-scratch:cli -c 'echo hi'
```

Expected: error (executable file not found / no such file)

- [ ] **Step 7: Commit** (only if the user asked to commit)

```bash
git add docker/golang-scratch/Dockerfile \
  docker/golang-scratch/compose.yaml \
  docker/golang-scratch/README.md
git commit -m "$(cat <<'EOF'
feat(docker): add golang-scratch Dockerfile and compose

EOF
)"
```

---

## Spec coverage check

| Spec requirement | Task |
| ---------------- | ---- |
| `docker/golang-scratch/` layout | 1–4 |
| Standalone module | 1 |
| `cmd/server` + `cmd/cli` | 3 |
| `TARGET` build-arg | 4 |
| `golang:1.26` → `scratch` | 4 |
| `/` + `/healthz` | 2–3 |
| `compose.yaml` on `:8080` | 4 |
| README + hardening note | 4 |
| No certs / non-root / CI | respected (omitted) |

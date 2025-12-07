FROM golang:1.25.5-alpine3.23 AS builder
WORKDIR /app
ENV GO111MODULE=on CGO_ENABLED=0
# download dependency
COPY go.mod go.sum ./
RUN  go mod download

FROM golang:1.25.5-alpine3.23 AS release
# Copy from builder
COPY --from=builder /bin/server /bin/server
ENTRYPOINT ["./bin/server"]
EXPOSE 8080
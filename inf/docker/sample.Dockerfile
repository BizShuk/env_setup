FROM golang:1.25.5-alpine3.23 AS builder
WORKDIR /app
ENV GO111MODULE=on CGO_ENABLED=0

# download dependency
COPY main.go .
COPY go.mod .
COPY go.mod .
# RUN go mod download

# Copy current folder into WORKDIR
# COPY . .
RUN go mod download
# Statically compile the binary for compatibility with minimal images like 'scratch'
RUN CGO_ENABLED=0 GOOS=linux go build -o myapp .
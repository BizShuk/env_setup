---
name: Generate README
description: Analyze workspace and generate comprehensive README documentation with handlers, folder structure, external services, and run instructions
---

# Generate README Workflow

This workflow analyzes the current software project and generates comprehensive documentation in README.md.

## Step 1: Analyze Folder Structure

Scan the project directory structure and document:

| Column      | Description                                   |
| ----------- | --------------------------------------------- |
| Folder Path | Relative path from project root               |
| Purpose     | Brief description of what the folder contains |

Focus on key directories like:

- `handler/`, `controller/` - HTTP/RPC handlers
- `service/`, `business/` - Business logic
- `model/`, `entity/` - Data models
- `config/` - Configuration
- `util/`, `common/` - Utilities
- `gateway/`, `client/` - External service clients

## Step 2: Generate Handler List

Search for route registrations in `main.go`, `router/`, `handler/`, and `controller/` directories.

Document each handler with:

| Column           | Description                                |
| ---------------- | ------------------------------------------ |
| Protocol         | HTTP, gRPC, Thrift, etc.                   |
| Method           | GET, POST, PUT, DELETE (for HTTP)          |
| URL Path         | The endpoint path                          |
| Handler Function | Function name handling the request         |
| Description      | Brief description of what the handler does |

Search patterns:

- Look for `r.GET()`, `r.POST()`, `router.Handle()` patterns
- Check IDL/proto files for RPC definitions
- Look for `@router` or similar annotations in comments

## Step 3: Identify External Services

Scan `gateway/`, `client/`, `service/` directories for external service integrations.

Document each external service:

| Column       | Description                          |
| ------------ | ------------------------------------ |
| Service Type | RPC, HTTP, Database, Cache, MQ, etc. |
| Service Name | PSM or service identifier            |
| Description  | What the service is used for         |

Look for:

- RPC client initializations (`NewClient()`, `GetClient()`)
- HTTP clients with base URLs
- Database connections (MySQL, Redis, etc.)
- Message queue consumers/producers

## Step 4: Document How to Run/Test

Include the following sections:

### Prerequisites

- Go version, dependencies, environment setup

### Build & Run

```bash
# Example commands
./build.sh && ./output/bootstrap.sh
```

### Testing

```bash
# Unit tests
go test ./...

# Integration tests (if applicable)
go test -tags=integration ./...
```

### Local Development

- How to run locally with BOE/mock services
- Configuration files needed
- Environment variables

## Step 5: Generate README.md

Compile all gathered information into a well-structured README.md file with:

1. **Overview** - Brief project description
2. **Handler Context** - Handler list table
3. **Project Structure** - Folder structure table
4. **External Services** - Service dependencies table
5. **Running** - Build and run instructions
6. **Testing** - How to test the project
7. **Interfaces** - IDL/Proto file locations (if applicable)

---

## Output Format Example

```markdown
# Project Name

## Overview

Brief description of the project.

## APIs

| Method | Path          | Handler  | Description   |
| ------ | ------------- | -------- | ------------- |
| GET    | /api/v1/users | GetUsers | Get user list |

## Project Structure

| Folder   | Purpose               |
| -------- | --------------------- |
| handler/ | HTTP request handlers |
| service/ | Business logic        |

## External Services

| Type  | Service Name | Description     |
| ----- | ------------ | --------------- |
| RPC   | user.service | User management |
| Redis | cache.redis  | Session cache   |

## Running

\`\`\`bash
./build.sh && ./output/bootstrap.sh
\`\`\`

## Testing

\`\`\`bash
go test ./...
\`\`\`
```

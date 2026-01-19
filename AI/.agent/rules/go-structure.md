# Project Architecture & Coding Guidelines

## Tech Stack

- Language: Go (Golang)
- ORM: GORM
- Configuration: Standard `config` package

## Architectural Layers (Strict Rules)

### 1. Model Layer (`/model`)

- **Responsibility**: Database interactions only.
- **Rule**: All CRUD operations (Create, Save, Update, Delete) MUST be implemented as methods on the struct in the `model` package.
- **Forbidden**: Do not use `db.Create()` or `db.Save()` directly in `svc` or `handler` layers.
- **Example**:

    ```go
    // Good
    func (u *User) Create(db *gorm.DB) error { ... }
    
    // Bad (in service layer)
    db.Create(&user)
    ```

### 2. Service Layer (`/svc`)

- **Responsibility**: Pure domain logic and simple data manipulation.
- **Rule**: Contains business logic units. DO NOT contain complex E2E flows or HTTP specific logic.
- **Rule**: Should be called by `handler`.

### 3. Handler Layer (`/handler`)

- **Responsibility**: End-to-End (E2E) feature composition.
- **Rule**: Orchestrates multiple `svc` calls to fulfill a feature request.
- **Rule**: Handles HTTP request/response and input validation.

### 4. Config & Infrastructure (`/config`)

- **Responsibility**: Configuration loading and client initialization (DB, Redis, external APIs).

### 5. Command Layer (`/cmd`)

- **Responsibility**: Entry points for single executions or CLI tools.
- **Rule**: Replaces the logic typically found in `main.go` for specific tasks.

## Code Style

- Prefer table-driven tests.
- Use specific error wrapping.

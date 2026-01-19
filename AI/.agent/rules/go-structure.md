---
trigger: always_on
description: This is golang project structure
globs: **/*.go
scope: **/*.go
---

Structure Layers

MVC break down services into handler/service/config/utils/model packages. You can further create a sub module/package if there is more than one domains in the project.

### Config & Infrastructure (`config/`)

- **Responsibility**: Configuration loading and client initialization (DB, Redis, external APIs).

Service and handlers will get the configuration and client here directly from this place without initializing by themselves. The major sdk is github.com/spf13/viper. github.com/bizshuk/gosdk is a wrapper of it for defaulter configuration file load. Use github.com/bizshuk/gosdk to load and github.com/spf13/viper to get the value. Such database connection, external service client, env variables loading will happen here.

- **Example**:

    ```go
    // Good Example
    var trifectaClient *resty.Client

    func init() {
        trifectaClient = resty.New()
    }

    func GetTrifectaClient() *resty.Client {
        return trifectaClient
    }
    ```

Program has bee divided to 3 environments, local, prod, prod on server. Use `PROFILE` env variable to control whether it's `prod` or not. prod on server use Makefile to replace configuration file path and deploy to Ubuntu user level systemd service, by default, it's `PROFILE=prod` in Makefile. `CONFIG_DIR` also will be addressed in the Makefile


### Model Layer (`model/`)

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

### Utils Layer (`utils/`)

It is a place to store common use wrapper function. Such as character encoding/decoding functions, file open functions. Some long and repeated process can be abstracted to a simple function by using callback function as I only care about the content intead of how to open it. Example below.

    ```go
    func NewFileOpenCallback(fpath string, fn func(f *os.File) error) error {
        f, err := os.Open(fpath)
        if err != nil { 
            return fmt.Errorf("failed to open file: %w", err)
        }
        defer f.Close()
        if err := fn(f); err != nil {
            return err
        }

        return nil
    }
    ```

### Command Layer (`cmd/`)

It is a place storing command line which will run handler and service. It is a extension for pure main function. This majorly use
 github.com/spf13/cobra to implement. Sub command is broke down by domain and use flag and switch to run each modules.

    ```go
    var loaderCmd = &cobra.Command{
        Use:   "loader",
        Short: "A brief description of your command",
        Long:  ``,
        Run: func(cmd *cobra.Command, args []string) 
    {
        loaderKey, _ := cmd.Flags().GetString("loader")

        switch loaderKey {
            case TASK_TRIFECTA_SCHEDULE:
                ServiceCall()
        }
    }
    func ServiceCall() {
        TrifectaSchedule()
    }
    ```

### Service Layer (`svc/`, `service/`)

- **Responsibility**: It is a single domain service to external. It should be simple, clean, and testable.  It should not contain any business logic that is not related to its domain, but just how to handle the domain response. For example, downloading file from a webside or calling a service to get user profile.
- **Rule**: Contains single business logic only. DO NOT contain complex E2E flows or HTTP specific logic.
- **Rule**: Should be called by `handler`.

### Handler Layer (`handler/`)

- **Responsibility**: End-to-End (E2E) feature composition.
- **Rule**: Orchestrates multiple `svc` calls to fulfill a feature request.
- **Rule**: Handles HTTP request/response and input validation.

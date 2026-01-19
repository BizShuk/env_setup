# Instructions

### Frameworks

#### MVC

MVC break down services into handler/service/config/utils/model packages. You can further create a sub module/package if there is more than one domains in the project.

- `handler` is a entry of a feature and calling services. All logics between services will happen in this layer in order to keep services simple, clean, and testable.
- servicce is a single domain service to external

- `service` is a single domain service to external. It should be simple, clean, and testable.  It should not contain any business logic that is not related to its domain, but just how to handle the domain response. For example, downloading file from a webside, calling a service to get user profile.

- `model` is data struture place. Each model represets a single domain data untils it can be preseted in a primitive type of a programming language. Such `Stock` will have `Code` inside of it and `Code` can be ppreset by int type. No private type/method use in model, all public type/method. Majoly this use github.com/go-gorm/gorm to operate with database.
  - **Rule**: All CRUD operations (Create, Save, Update, Delete) MUST be implemented as methods on the struct in the `model` package.
  - **Forbidden**: Do not use `db.Create()` or `db.Save()` directly in `svc` or `handler` layers.
  - **Example**:

    ```go
    // Good
    func (u *User) Create(db *gorm.DB) error { ... }

    // Bad (in service layer)
    db.Create(&user)
    ```

- `config` is a place to load all configurations and clients. service and handlers will get the configuration and client here directly from this place without initializing itself. The major sdk is github.com/spf13/viper. github.com/bizshuk/gosdk is a wrapper of it for defaulter configuration file load. Use github.com/bizshuk/gosdk to load and github.com/spf13/viper to get the value. Such database connection, external service client, env variables loading will happen here.

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

- `cmd` is a place storing command line which will run handler and service. It is a extension for pure main function. This majorly use
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

- `utils` is a place to store common use wrapper function. Such as character encoding/decoding functions, file open functions. Some long and repeated process can be abstracted to a simple function by using callback function as I only care about the content intead of how to open it. Example below.

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

#### Unit testing

function/method/struct can be categorized to aggregated one and simple one.

- Aggregated function/method/struct is like handler which combined related services logic. Don't do unit testing in this layer, but do business scenario testing/integration testing
- Simple function/method/struct is like service/model/config/utils. These are the unit testing focus on.

### Golang

applyTo: '**.go'

This is languange I prefer by default if project level GEMINI.md is not explicitly mentioning the programming language to use. There are few SDKs to use by default.

- github.com/bizshuk/gosdk
- github.com/go-gorm/gorm
- github.com/spf13/viper
- github.com/spf13/cobra

### Typescript/Javascript

applyTo: '**.ts/**.js'

If the project involve web page design. This language will be used for front-end implementation.

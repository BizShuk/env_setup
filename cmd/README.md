# smain - Shuk Usage CLI

A Go-based CLI utility tool built with Cobra.

## Commands

- **`hello`** (alias: `hi`): Says hello to the world using logrus.
- **`greet`**: Greets a user by name.
  - Usage: `./smain greet --name <name>`
- **`calc`**: Performs simple arithmetic operations (add, sub).
  - Usage: `./smain calc --num1 <num> --num2 <num> --operation <add|sub>`
- **`fetch`**: Fetches and prints content from a URL.
  - Usage: `./smain fetch --url <url>`
- **`ls`**: Lists directory contents.
  - Usage: `./smain ls --path <path>`
- **`config`**: Manage configuration settings in `config.json`.
  - `set`: `./smain config set --key <key> --value <value>`
  - `get`: `./smain config get --key <key>`
- **`list`**: Lists all available commands in this application.

## Development

### Prerequisites

- Go 1.25.4+

### Build

To build the application, run:

```bash
go build -o smain
```

### Run

```bash
./smain [command]
```

# Setup Scripts

This directory contains scripts for installing and configuring various development environments and tools.

## OS Setup

- **`mac_setup.sh`**: Main setup script for macOS environments.
- **`ubuntu_setup.sh`**: Main setup script for Ubuntu Linux environments.

## Tool-specific Setup

- **`bash_env_setup.sh`**: Configures the bash environment and aliases.
- **`go_setup.sh`**: Installs and configures the Go programming language.
- **`vim_setup.sh`**: Configures Vim with preferred settings.
- **`kubectl_mac_setup.sh`**: Sets up `kubectl` for Kubernetes management on macOS.
- **`git_setup.sh`** & **`git-secret.sh`**: Configures Git and `git-secret` for sensitive data management.
- **`ctags_setup.sh`**: Installs and configures Ctags.
- **`astyle_setup.sh`**: Sets up Artistic Style for code formatting.
- **`dnsmasq_setup.sh`**: Configures Dnsmasq for local DNS management.
- **`openssl_mac_setup.sh`**: OpenSSL configuration for macOS.
- **`pkg-config_setup.sh`**: Sets up `pkg-config`.
- **`libgit2_setup.sh`**: Installs `libgit2`.

## Other

- **`settings.sh`**: Shared settings and variables used by other scripts.
- **`disk/`**: Subdirectory for disk-related setup (e.g., formatting, mounting).

## Usage

Most scripts can be run directly:

```bash
./<script_name>.sh
```

Ensure you review the scripts before execution as some may require `sudo` or modify system-wide configurations.

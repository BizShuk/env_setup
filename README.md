# Env Setup & DevOps Toolbox

This repository is a comprehensive collection of server setup scripts, development utilities, and technical documentation. It serves as a personal environment setup and knowledge base for various DevOps and development tools.

## Project Structure

- **`.agents/`**: Configuration for specialized agent commands (e.g., speckit).
- **`bin/`**: A collection of shell utility scripts for system maintenance, network checks, and general productivity.
  - `backup`: Backup utility.
  - `check_alive`, `check_service`: Monitoring scripts.
  - `generate_https_cert`: SSL certificate generation helper.
  - `list_big_files.sh`: Disk usage utility.
- **`cmd/`**: A Go-based CLI tool (`smain`) providing various utilities like `fetch`, `calc`, and directory listing.
- **`setup/`**: Installation and configuration scripts for various environments and tools.
  - `mac_setup.sh`, `ubuntu_setup.sh`: OS-specific setup scripts.
  - `go_setup.sh`, `kubectl_mac_setup.sh`, `vim_setup.sh`: Tool-specific installers.
- **`pkg/`**: Documentation, notes, and configuration snippets for various technologies (Kubernetes, Docker, Git, Ansible, etc.).
- **`docker/`**: Docker-related configurations and sample files.
- **`mac/`**: macOS specific setup scripts, AppleScripts, and notes.
- **`grafana/` & `prometheus/`**: Monitoring configuration for Node Exporter and Prometheus.
- **`specs/`**: Project specifications and discovery notes.
- **`troubleshooting/`**: Scripts and notes for resolving common system issues.

## Key Components

### Go CLI Tool (`cmd/`)

The project includes a Go CLI built with Cobra.

- **Build**: `cd cmd && go build -o smain`
- **Commands**:
  - `ls`: List directory contents.
  - `fetch`: Fetch data (e.g., from URLs).
  - `calc`: Basic calculator.
  - `config`: Manage configurations.

### Setup Scripts (`setup/`)

Automated setup scripts for setting up development environments on macOS and Ubuntu. Use these scripts to quickly initialize a new machine with preferred tools and configurations.

## Reading List & Resources

### Linux Server

- [Linux A-Z Commands for Beginners](http://www.sandwichbite.com/linux-a-z-commands-for-beginners/)
- [First 5 mins on Server](http://plusbryan.com/my-first-5-minutes-on-a-server-or-essential-security-for-linux-servers)
- [Fishing for Hackers](https://sysdig.com/blog/fishing-for-hackers/)

### SSL/TLS & OpenSSL

- [openssl CA](https://jamielinux.com/docs/openssl-certificate-authority/introduction.html)
- [self-signed SSL Certificate](http://www.akadia.com/services/ssh_test_certificate.html)
- [SSL basic](http://csc.ocean-pioneer.com/docum/ssl_basic.html)

### DevOps & Engineering

- [GitFlow considered harmful](http://endoflineblog.com/gitflow-considered-harmful)
- [Google Site Reliability Engineering](https://landing.google.com/sre/)
- [cAdvisor](https://github.com/google/cadvisor)

---

[LICENSE](LICENSE)




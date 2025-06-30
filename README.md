# OpenTelemetry Collector Contrib Installer

A robust bash script for installing OpenTelemetry Collector Contrib on Linux systems with interactive and automated modes.

## Features

- **Dual modes**: Interactive (with progress bars & ASCII art) or basic (for automation)
- **Multi-architecture support**: x86_64, amd64, aarch64, arm64
- **Multi-distro support**: Ubuntu, Debian, RHEL, CentOS, Oracle Linux, Amazon Linux, SUSE
- **Smart cleanup**: Automatically removes existing installations
- **Flexible configuration**: Option to replace package config with custom config
- **Version flexibility**: Specify any collector version

## Installation Methods

### Method 1: Direct execution via curl (Recommended)

```bash
# Default installation (interactive mode, keeps package config)
sudo /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/cubeapm/Otel-contrib-installation/main/otel-contrib-install.sh)"

# With custom arguments - use -- to separate curl options from script options
sudo /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/cubeapm/Otel-contrib-installation/main/otel-contrib-install.sh)" -- --mode basic

sudo /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/cubeapm/Otel-contrib-installation/main/otel-contrib-install.sh)" -- --version 0.125.0 --replace-config

sudo /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/cubeapm/Otel-contrib-installation/main/otel-contrib-install.sh)" -- --mode basic --version 0.125.0
```

### Method 2: Download and execute locally

```bash
# Download the script
curl -fsSL https://raw.githubusercontent.com/cubeapm/Otel-contrib-installation/main/otel-contrib-install.sh -o otel-contrib-install.sh

# Make it executable
chmod +x otel-contrib-install.sh

# Run with desired options
sudo ./otel-contrib-install.sh
sudo ./otel-contrib-install.sh --mode basic
sudo ./otel-contrib-install.sh --version 0.125.0 --replace-config
```

## Options

| Option             | Description                               | Default       |
| ------------------ | ----------------------------------------- | ------------- |
| `--mode`           | `interactive` or `basic`                  | `interactive` |
| `--version`        | Collector version (e.g., 0.126.0)         | `0.126.0`     |
| `--replace-config` | Replace package config with custom config | `false`       |
| `--help`           | Show usage information                    | -             |

## Requirements

- **OS**: Linux (Ubuntu, Debian, RHEL, CentOS, Oracle Linux, Amazon Linux, SUSE)
- **Architecture**: x86_64, amd64, aarch64, arm64
- **Privileges**: sudo recommended for full functionality
- **Tools**: curl, systemctl

## What It Does

1. Detects OS and architecture
2. Removes existing installations cleanly
3. Downloads appropriate otelcol-contrib binary
4. Installs via package manager (deb/rpm) or tar
5. Optionally downloads and installs custom config
6. Sets up systemd service

## Configuration

### Default Behavior

By default, the script keeps the package's default configuration. To use a custom configuration, add the `--replace-config` flag.

### Config Replacement

When using `--replace-config`:

- Downloads custom config from the repository
- Creates timestamped backup of existing config (e.g., `config_20241201_143022.yaml`)
- Replaces the config with the custom version
- Backup is stored in the same directory as the config file

## Post-Installation

```bash
# Start the service
sudo systemctl start otelcol-contrib

# Check status
sudo systemctl status otelcol-contrib

# View logs
sudo journalctl -u otelcol-contrib -f

# Edit config
sudo nano /etc/otelcol-contrib/config.yaml
```

## File Locations

- **Binary**: `/usr/local/bin/otelcol-contrib`
- **Config**: `/etc/otelcol-contrib/config.yaml`
- **Service**: `otelcol-contrib.service`

---

_Supports OpenTelemetry Collector Contrib versions from the [official releases](https://github.com/open-telemetry/opentelemetry-collector-releases)_

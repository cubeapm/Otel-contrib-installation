# OpenTelemetry Collector Contrib Installer

A robust bash script for installing OpenTelemetry Collector Contrib on Linux systems with interactive and automated modes.

## Features

- **Dual modes**: Interactive (with progress bars & ASCII art) or basic (for automation)
- **Multi-architecture support**: x86_64, amd64, aarch64, arm64
- **Multi-distro support**: Ubuntu, Debian, RHEL, CentOS, Amazon Linux, SUSE
- **Smart cleanup**: Automatically removes existing installations
- **Custom configuration**: Replaces package config with custom config by default
- **Version flexibility**: Specify any collector version

## Quick Start

```bash
# Interactive installation with custom config (default)
sudo ./otel-contrib-install.sh

# Basic mode for automation with custom config
sudo ./otel-contrib-install.sh --mode basic

# Keep package default config instead of custom config
sudo ./otel-contrib-install.sh --no-replace-config

# Specific version with package default config
sudo ./otel-contrib-install.sh --version 0.125.0 --no-replace-config
```

## Options

| Option                | Description                                   | Default       |
| --------------------- | --------------------------------------------- | ------------- |
| `--mode`              | `interactive` or `basic`                      | `interactive` |
| `--version`           | Collector version (e.g., 0.126.0)             | `0.126.0`     |
| `--no-replace-config` | Skip replacing config (keeps package default) | `false`       |
| `--help`              | Show usage information                        | -             |

## Requirements

- **OS**: Linux (Ubuntu, Debian, RHEL, CentOS, Amazon Linux, SUSE)
- **Architecture**: x86_64, amd64, aarch64, arm64
- **Privileges**: sudo recommended for full functionality
- **Tools**: curl, systemctl

## What It Does

1. Detects OS and architecture
2. Removes existing installations cleanly
3. Downloads appropriate collector binary
4. Installs via package manager (deb/rpm) or tar
5. Downloads and installs custom config (by default)
6. Sets up systemd service

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

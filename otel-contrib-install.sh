#!/bin/bash

# OpenTelemetry Collector Contrib Installation Script
# Installer with multiple modes: interactive (default) and basic
# Use https://www.shellcheck.net/ to check for errors upon modification.

set -o errexit

# OTEL Collector Contrib configuration
OTEL_VERSION="0.126.0"
OTEL_BASE_URL="https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v${OTEL_VERSION}"
OTEL_SERVICE_NAME="otelcol-contrib"
OTEL_SERVICE_PATH="/usr/local/bin/${OTEL_SERVICE_NAME}"
OTEL_CONFIG_DIR="/etc/otelcol-contrib"
OTEL_CONFIG_FILE="${OTEL_CONFIG_DIR}/config.yaml"
OTEL_CONFIG_URL="https://raw.githubusercontent.com/cubeapm/Otel-contrib-installation/main/config.yaml"

# Supported architectures (Linux only as per requirements)
LINUX_SUPPORTED_ARCH=("x86_64" "amd64" "aarch64" "arm64")

# Script modes
MODE="interactive"  # Default mode: interactive or basic
REPLACE_CONFIG=false  # Whether to replace config file (default is false)

# Colors for interactive mode
GREEN='\033[0;32m'
BRIGHT_GREEN='\033[1;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Usage function
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "OPTIONS:"
    echo "  --mode MODE          Set installation mode: 'interactive' (default) or 'basic'"
    echo "  --version VERSION    Specify OTEL Collector version (default: 0.126.0)"
    echo "  --replace-config     Replace the default config with custom config (default: keep package default)"
    echo "  --help               Show this help message"
    echo ""
    echo "MODES:"
    echo "  interactive          Full interactive experience with progress bars and styling"
    echo "  basic               Simple output for automation (success/failed only)"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Interactive mode, default version, keep package config"
    echo "  $0 --mode basic                      # Basic mode, default version, keep package config"
    echo "  $0 --version 0.125.0                 # Interactive mode, specific version, keep package config"
    echo "  $0 --replace-config                  # Interactive mode, default version, replace with custom config"
    echo "  $0 --mode basic --version 0.125.0 --replace-config     # Basic mode, specific version, replace with custom config"
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --mode)
                MODE="$2"
                if [[ "$MODE" != "interactive" && "$MODE" != "basic" ]]; then
                    echo "Error: Invalid mode '$MODE'. Must be 'interactive' or 'basic'."
                    exit 1
                fi
                shift 2
                ;;
            --version)
                OTEL_VERSION="$2"
                if [[ -z "$OTEL_VERSION" ]]; then
                    echo "Error: Version cannot be empty."
                    exit 1
                fi
                # Basic version format validation (should match semantic versioning pattern)
                if [[ ! "$OTEL_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                    echo "Warning: Version '$OTEL_VERSION' does not follow semantic versioning format (e.g., 0.126.0)."
                    echo "Proceeding anyway, but download may fail if version doesn't exist."
                fi
                # Update the base URL with the new version
                OTEL_BASE_URL="https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v${OTEL_VERSION}"
                shift 2
                ;;
            --replace-config)
                REPLACE_CONFIG=true
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                echo "Error: Unknown option '$1'"
                show_usage
                exit 1
                ;;
        esac
    done
}

# Output functions based on mode
log_info() {
    local message="$1"
    if [[ "$MODE" == "interactive" ]]; then
        echo -e "${CYAN}[OTEL]${NC} $message"
    fi
    # Basic mode: no info messages for automation
}

log_success() {
    local message="$1"
    if [[ "$MODE" == "interactive" ]]; then
        echo -e "${GREEN}[SUCCESS]${NC} $message"
    fi
    # Basic mode: success messages handled by main completion function
}

log_error() {
    local message="$1"
    if [[ "$MODE" == "interactive" ]]; then
        echo -e "${RED}[ERROR]${NC} $message" >&2
    fi
    # Basic mode: error messages handled by error handler
}

log_warning() {
    local message="$1"
    if [[ "$MODE" == "interactive" ]]; then
        echo -e "${YELLOW}[WARNING]${NC} $message"
    fi
    # Basic mode: no warning messages for automation
}

# OTEL-style ASCII art for interactive mode
print_otel_header() {
    if [[ "$MODE" != "interactive" ]]; then
        return
    fi
    
    clear
    echo -e "${BRIGHT_GREEN}"
    cat << 'EOF'
    ╔═══════════════════════════════════════════════════════════════════════════════╗
    ║                                                                               ║
    ║    ██████╗ ████████╗███████╗██╗         ██████╗ ██████╗ ██╗     ██╗         ║
    ║   ██╔═══██╗╚══██╔══╝██╔════╝██║        ██╔════╝██╔═══██╗██║     ██║         ║
    ║   ██║   ██║   ██║   █████╗  ██║        ██║     ██║   ██║██║     ██║         ║
    ║   ██║   ██║   ██║   ██╔══╝  ██║        ██║     ██║   ██║██║     ██║         ║
    ║   ╚██████╔╝   ██║   ███████╗███████╗   ╚██████╗╚██████╔╝███████╗███████╗    ║
    ║    ╚═════╝    ╚═╝   ╚══════╝╚══════╝    ╚═════╝ ╚═════╝ ╚══════╝╚══════╝    ║
    ║                                                                               ║
    ║                    ██████╗ ██████╗ ███╗   ██╗████████╗██████╗ ██╗██████╗     ║
    ║                   ██╔════╝██╔═══██╗████╗  ██║╚══██╔══╝██╔══██╗██║██╔══██╗    ║
    ║                   ██║     ██║   ██║██╔██╗ ██║   ██║   ██████╔╝██║██████╔╝    ║
    ║                   ██║     ██║   ██║██║╚██╗██║   ██║   ██╔══██╗██║██╔══██╗    ║
    ║                   ╚██████╗╚██████╔╝██║ ╚████║   ██║   ██║  ██║██║██████╔╝    ║
    ║                    ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚═╝  ╚═╝╚═╝╚═════╝     ║
    ║                                                                               ║
    ║                           I N S T A L L E R   v${OTEL_VERSION}                        ║
    ║                                                                               ║
    ╚═══════════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo
}

# Progress indicator for interactive mode
otel_progress() {
    if [[ "$MODE" != "interactive" ]]; then
        return
    fi
    
    local step=$1
    local total=$2
    local message=$3
    local status=$4
    
    local progress=$((step * 100 / total))
    local filled=$((progress / 5))
    local empty=$((20 - filled))
    
    echo -ne "\r${CYAN}[OTEL]${NC} "
    echo -ne "${BOLD}Step ${step}/${total}:${NC} "
    echo -ne "${GREEN}["
    
    for ((i=0; i<filled; i++)); do
        echo -ne "█"
    done
    
    for ((i=0; i<empty; i++)); do
        echo -ne "░"
    done
    
    echo -ne "]${NC} "
    echo -ne "${progress}% "
    
    case $status in
        "running")
            echo -ne "${YELLOW}⚡ ${message}...${NC}"
            ;;
        "success")
            echo -ne "${GREEN}✓ ${message}${NC}"
            ;;
        "error")
            echo -ne "${RED}✗ ${message}${NC}"
            ;;
        *)
            echo -ne "${CYAN}${message}${NC}"
            ;;
    esac
    
    if [[ $status == "success" || $status == "error" ]]; then
        echo
    fi
}

# Typing effect for interactive mode
otel_type() {
    if [[ "$MODE" != "interactive" ]]; then
        return
    fi
    
    local text=$1
    local delay=${2:-0.03}
    
    echo -ne "${GREEN}"
    for ((i=0; i<${#text}; i++)); do
        echo -ne "${text:$i:1}"
        sleep $delay
    done
    echo -e "${NC}"
}

# Error handler
otel_error() {
    local exit_code=$?
    local error_line=${BASH_LINENO[0]}
    local error_command="${BASH_COMMAND}"
    
    if [[ "$MODE" == "interactive" ]]; then
        echo
        echo -e "${RED}╔═══════════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║                                                                               ║${NC}"
        echo -e "${RED}║                              INSTALLATION FAILED                             ║${NC}"
        echo -e "${RED}║                                                                               ║${NC}"
        echo -e "${RED}║  OpenTelemetry Collector installation has encountered an error.              ║${NC}"
        echo -e "${RED}║                                                                               ║${NC}"
        echo -e "${RED}║  Error Details:                                                               ║${NC}"
        echo -e "${RED}║  Exit Code: ${exit_code}                                                              ║${NC}"
        echo -e "${RED}║  Line: ${error_line}                                                                  ║${NC}"
        printf "${RED}║  Command: %-63s ║${NC}\n" "${error_command:0:63}"
        if [[ ${#error_command} -gt 63 ]]; then
            printf "${RED}║           %-63s ║${NC}\n" "${error_command:63:63}"
        fi
        echo -e "${RED}║                                                                               ║${NC}"
        echo -e "${RED}╚═══════════════════════════════════════════════════════════════════════════════╝${NC}"
        
        # Show context if available
        echo
        echo -e "${YELLOW}Context information:${NC}"
        if [[ -n "${download_file:-}" ]]; then
            echo -e "${CYAN}Downloaded file: ${download_file}${NC}"
        fi
        if [[ -n "${download_url:-}" ]]; then
            echo -e "${CYAN}Download URL: ${download_url}${NC}"
        fi
        if [[ -n "${arch_name:-}" ]]; then
            echo -e "${CYAN}Architecture: ${arch_name}${NC}"
        fi
        if [[ -n "${package_manager:-}" ]]; then
            echo -e "${CYAN}Package Manager: ${package_manager}${NC}"
        fi
    elif [[ "$MODE" == "basic" ]]; then
        echo "failed"
    fi
    
    exit 1
}

# Success handler
otel_success() {
    if [[ "$MODE" == "interactive" ]]; then
        echo
        echo -e "${BRIGHT_GREEN}╔═══════════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${BRIGHT_GREEN}║                                                                               ║${NC}"
        echo -e "${BRIGHT_GREEN}║                           INSTALLATION COMPLETE                              ║${NC}"
        echo -e "${BRIGHT_GREEN}║                                                                               ║${NC}"
        echo -e "${BRIGHT_GREEN}║  OpenTelemetry Collector Contrib has been successfully installed!            ║${NC}"
        echo -e "${BRIGHT_GREEN}║                                                                               ║${NC}"
        echo -e "${BRIGHT_GREEN}║  Service: systemctl start ${OTEL_SERVICE_NAME}                                      ║${NC}"
        echo -e "${BRIGHT_GREEN}║  Config:  ${OTEL_CONFIG_FILE}                                    ║${NC}"
        echo -e "${BRIGHT_GREEN}║                                                                               ║${NC}"
        echo -e "${BRIGHT_GREEN}╚═══════════════════════════════════════════════════════════════════════════════╝${NC}"
    elif [[ "$MODE" == "basic" ]]; then
        echo "success"
    fi
}

# Utility functions
is_command_present() {
    type "$1" >/dev/null 2>&1
}

# Check if running on Linux
check_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        os_name="$(cat /etc/*-release 2>/dev/null | awk -F= '$1 == "NAME" { gsub(/"/, ""); print $2; exit }' || echo "Unknown Linux")"
        
        case "$os_name" in
            Ubuntu*|Debian*|Linux\ Mint*)
                package_manager="deb"
                install_cmd="dpkg -i"
                ;;
            Amazon\ Linux*|Red\ Hat*|CentOS*|Rocky*|Oracle\ Linux*)
                package_manager="rpm"
                install_cmd="rpm -i"
                ;;
            SLES*|openSUSE*)
                package_manager="rpm"
                install_cmd="rpm -i"
                ;;
            *)
                package_manager="tar"
                install_cmd="tar"
                ;;
        esac
        return 0
    else
        return 1
    fi
}

# Check architecture and determine download file
check_architecture() {
    arch_name="$(uname -m)"
    
    # Normalize architecture names
    case $arch_name in
        x86_64)
            arch_name="amd64"
            ;;
        aarch64)
            arch_name="arm64"
            ;;
    esac
    
    # Check if architecture is supported
    if [[ ! ${LINUX_SUPPORTED_ARCH[*]} =~ $arch_name ]]; then
        return 1
    fi
    
    # Determine the correct file to download based on architecture and package manager
    case "${arch_name}_${package_manager}" in
        "arm64_deb")
            download_file="otelcol-contrib_${OTEL_VERSION}_linux_arm64.deb"
            ;;
        "arm64_rpm")
            download_file="otelcol-contrib_${OTEL_VERSION}_linux_arm64.rpm"
            ;;
        "arm64_tar"|"amd64_tar")
            if [[ $arch_name == "amd64" ]]; then
                download_file="otelcol-contrib_${OTEL_VERSION}_linux_amd64.tar.gz"
            else
                download_file="otelcol-contrib_${OTEL_VERSION}_linux_arm64.tar.gz"
            fi
            ;;
        "amd64_deb")
            download_file="otelcol-contrib_${OTEL_VERSION}_linux_amd64.deb"
            ;;
        "amd64_rpm")
            download_file="otelcol-contrib_${OTEL_VERSION}_linux_amd64.rpm"
            ;;
        *)
            return 1
            ;;
    esac
    
    download_url="${OTEL_BASE_URL}/${download_file}"
    return 0
}

# Download the OTEL Collector file
download_otel() {
    status_code="$(curl --fail --no-progress-meter -L -o "$download_file" -w "%{http_code}" "$download_url" 2>/dev/null || echo "000")"
    
    if [[ $status_code == "200" ]]; then
        return 0
    else
        log_error "Download failed with HTTP status: $status_code"
        log_error "URL: $download_url"
        return 1
    fi
}

# Install the downloaded file
install_otel() {
    if [[ "$MODE" == "interactive" ]]; then
        echo
        echo -e "${CYAN}[OTEL]${NC} ${BOLD}Installation Command:${NC}"
    fi
    
    case $package_manager in
        "deb")
            log_info "Running: $install_cmd $download_file"
            if [[ "$MODE" == "interactive" ]]; then
                echo
            fi
            if ! $install_cmd "$download_file"; then
                log_error "Package installation failed"
                return 1
            fi
            ;;
        "rpm")
            log_info "Running: $install_cmd $download_file"
            if [[ "$MODE" == "interactive" ]]; then
                echo
            fi
            if ! $install_cmd "$download_file"; then
                log_error "Package installation failed"
                return 1
            fi
            ;;
        "tar")
            log_info "Running: tar -xzf $download_file"
            if [[ "$MODE" == "interactive" ]]; then
                echo
            fi
            if ! tar -xzf "$download_file"; then
                log_error "Failed to extract tar file"
                return 1
            fi
            
            # Find the binary in the extracted files
            if [[ -f "otelcol-contrib" ]]; then
                binary_name="otelcol-contrib"
            else
                log_error "No OTEL contrib binary found in extracted files"
                log_error "Expected: otelcol-contrib"
                log_error "Available files:"
                ls -la
                return 1
            fi
            
            log_info "Moving binary: $binary_name -> $OTEL_SERVICE_PATH"
            # Move binary to system path
            if ! chmod +x "$binary_name"; then
                log_error "Failed to make binary executable"
                return 1
            fi
            if ! mv "$binary_name" "$OTEL_SERVICE_PATH"; then
                log_error "Failed to move binary to system path"
                return 1
            fi
            ;;
        *)
            log_error "Unsupported package manager: $package_manager"
            return 1
            ;;
    esac
    if [[ "$MODE" == "interactive" ]]; then
        echo
    fi
    return 0
}

# Create configuration file in current directory (to avoid conflicts)
create_config() {
    local temp_config="config.yaml"
    
    log_info "Downloading configuration file from: $OTEL_CONFIG_URL"
    
    # Download the config file
    local status_code
    status_code="$(curl --fail --no-progress-meter -L -o "$temp_config" -w "%{http_code}" "$OTEL_CONFIG_URL" 2>/dev/null || echo "000")"
    
    if [[ $status_code == "200" ]]; then
        log_success "Configuration file downloaded successfully: $temp_config"
        
        # Verify the downloaded file is not empty and appears to be YAML
        if [[ ! -s "$temp_config" ]]; then
            log_error "Downloaded config file is empty"
            return 1
        fi
        
        # Basic YAML validation - check if it contains some expected OTEL structure
        if ! grep -q "receivers:\|exporters:\|processors:" "$temp_config"; then
            log_warning "Downloaded file may not be a valid OTEL config (missing expected sections)"
            log_info "Contents preview:"
            head -10 "$temp_config" 2>/dev/null || true
        fi
        
        log_info "Configuration file ready: $temp_config"
        return 0
    else
        log_error "Failed to download config file from: $OTEL_CONFIG_URL"
        log_error "HTTP status code: $status_code"
        log_error "Config download is mandatory - no fallback will be used"
        return 1
    fi
}

# Replace the package-created config with our custom one
replace_config() {
    local temp_config="config.yaml"
    
    if [[ "$MODE" == "interactive" ]]; then
        echo
        echo -e "${CYAN}[OTEL]${NC} ${BOLD}Replacing package config with custom config...${NC}"
    fi
    
    # Check if our temp config exists
    if [[ ! -f "$temp_config" ]]; then
        log_error "Temporary config file not found: $temp_config"
        return 1
    fi
    
    # Check if package created the config directory
    if [[ ! -d "$OTEL_CONFIG_DIR" ]]; then
        log_info "Creating config directory: $OTEL_CONFIG_DIR"
        if ! mkdir -p "$OTEL_CONFIG_DIR"; then
            log_error "Failed to create config directory: $OTEL_CONFIG_DIR"
            return 1
        fi
    fi
    
    # Backup existing config if it exists
    if [[ -f "$OTEL_CONFIG_FILE" ]]; then
        local backup_file="${OTEL_CONFIG_FILE%/*}/config_$(date +%Y%m%d_%H%M%S).yaml"
        log_info "Backing up existing config: $backup_file"
        if ! cp "$OTEL_CONFIG_FILE" "$backup_file"; then
            log_warning "Failed to backup existing config"
        else
            log_success "Config backed up successfully: $backup_file"
        fi
    fi
    
    # Replace with our config
    log_info "Installing config: $temp_config -> $OTEL_CONFIG_FILE"
    if ! cp "$temp_config" "$OTEL_CONFIG_FILE"; then
        log_error "Failed to install config file"
        return 1
    fi
    
    # Set proper permissions
    if ! chmod 644 "$OTEL_CONFIG_FILE"; then
        log_warning "Failed to set config file permissions"
    fi
    
    log_success "Configuration successfully installed"
    return 0
}

# Cleanup function
cleanup() {
    # Keep downloaded files for user reference
    # Clean up temporary config file if it exists
    if [[ -f "config.yaml" ]]; then
        log_info "Cleaning up temporary config file"
        rm -f "config.yaml"
    fi
}

# Check and remove existing installation
check_and_remove_existing() {
    local existing_service=false
    local existing_binary=false
    local existing_config=false
    local package_removed=false
    
    # Check if service exists and is running
    if is_command_present systemctl; then
        if systemctl list-units --full -all | grep -Fq "${OTEL_SERVICE_NAME}.service"; then
            existing_service=true
            log_info "Found existing ${OTEL_SERVICE_NAME} service"
            
            # Reset failed state first if needed
            if systemctl is-failed --quiet "${OTEL_SERVICE_NAME}.service" 2>/dev/null; then
                log_info "Resetting failed service state before cleanup"
                systemctl reset-failed "${OTEL_SERVICE_NAME}.service" 2>/dev/null || true
            fi
            
            # Stop the service if it's running
            if systemctl is-active --quiet "${OTEL_SERVICE_NAME}.service"; then
                log_info "Stopping existing ${OTEL_SERVICE_NAME} service"
                if ! systemctl stop "${OTEL_SERVICE_NAME}.service"; then
                    log_warning "Failed to stop ${OTEL_SERVICE_NAME} service"
                fi
            fi
            
            # Disable the service
            if systemctl is-enabled --quiet "${OTEL_SERVICE_NAME}.service" 2>/dev/null; then
                log_info "Disabling existing ${OTEL_SERVICE_NAME} service"
                if ! systemctl disable "${OTEL_SERVICE_NAME}.service"; then
                    log_warning "Failed to disable ${OTEL_SERVICE_NAME} service"
                fi
            fi
        fi
    fi
    
    # Try to remove the package first (this handles most cleanup automatically)
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        local current_os_name="$(cat /etc/*-release 2>/dev/null | awk -F= '$1 == "NAME" { gsub(/"/, ""); print $2; exit }' || echo "Unknown Linux")"
        
        case "$current_os_name" in
            Ubuntu*|Debian*|Linux\ Mint*)
                if is_command_present dpkg && dpkg -l | grep -q "otelcol-contrib"; then
                    log_info "Purging existing deb package (includes config files)"
                    # Use --purge to remove config files too
                    if dpkg --purge otelcol-contrib 2>/dev/null; then
                        package_removed=true
                        log_success "Package purged successfully"
                    else
                        log_warning "Failed to purge deb package, trying manual cleanup"
                    fi
                fi
                ;;
            Amazon\ Linux*|Red\ Hat*|CentOS*|Rocky*|Oracle\ Linux*)
                if is_command_present rpm && rpm -qa | grep -q "otelcol-contrib"; then
                    log_info "Removing existing rpm package"
                    if rpm -e otelcol-contrib 2>/dev/null; then
                        package_removed=true
                        log_success "Package removed successfully"
                    else
                        log_warning "Failed to remove rpm package, trying manual cleanup"
                    fi
                fi
                ;;
            SLES*|openSUSE*)
                if is_command_present rpm && rpm -qa | grep -q "otelcol-contrib"; then
                    log_info "Removing existing rpm package"
                    if rpm -e otelcol-contrib 2>/dev/null; then
                        package_removed=true
                        log_success "Package removed successfully"
                    else
                        log_warning "Failed to remove rpm package, trying manual cleanup"
                    fi
                fi
                ;;
        esac
    fi
    
    # Manual cleanup if package removal failed or for tar installations
    
    # Check if binary exists (after package removal attempt)
    if [[ -f "$OTEL_SERVICE_PATH" ]]; then
        existing_binary=true
        log_info "Found existing binary: $OTEL_SERVICE_PATH"
        log_info "Removing existing binary"
        if ! rm -f "$OTEL_SERVICE_PATH"; then
            log_warning "Failed to remove existing binary: $OTEL_SERVICE_PATH"
        fi
    fi
    
    # Check if config file exists (after package removal attempt)
    if [[ -f "$OTEL_CONFIG_FILE" ]]; then
        existing_config=true
        log_info "Found existing config: $OTEL_CONFIG_FILE"
        log_info "Backing up and removing existing config"
        
        # Create backup with timestamp
        local backup_file="${OTEL_CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
        if cp "$OTEL_CONFIG_FILE" "$backup_file" 2>/dev/null; then
            log_info "Config backed up to: $backup_file"
        else
            log_warning "Failed to backup existing config"
        fi
        
        if ! rm -f "$OTEL_CONFIG_FILE"; then
            log_warning "Failed to remove existing config: $OTEL_CONFIG_FILE"
        fi
    fi
    
    # Check if config directory exists and is empty, remove it
    if [[ -d "$OTEL_CONFIG_DIR" ]]; then
        if [[ -z "$(ls -A "$OTEL_CONFIG_DIR" 2>/dev/null)" ]]; then
            log_info "Removing empty config directory: $OTEL_CONFIG_DIR"
            if ! rmdir "$OTEL_CONFIG_DIR"; then
                log_warning "Failed to remove config directory: $OTEL_CONFIG_DIR"
            fi
        else
            log_info "Config directory not empty, keeping: $OTEL_CONFIG_DIR"
        fi
    fi
    
    # Clean up systemd service files that might remain after package removal
    local systemd_service_file="/usr/lib/systemd/system/${OTEL_SERVICE_NAME}.service"
    local systemd_service_file_alt="/etc/systemd/system/${OTEL_SERVICE_NAME}.service"
    
    for service_file in "$systemd_service_file" "$systemd_service_file_alt"; do
        if [[ -f "$service_file" ]]; then
            log_info "Removing systemd service file: $service_file"
            if ! rm -f "$service_file"; then
                log_warning "Failed to remove service file: $service_file"
            fi
        fi
    done
    
    # Always reload systemd if we had any service-related changes
    if [[ "$existing_service" == "true" || "$package_removed" == "true" ]] && is_command_present systemctl; then
        log_info "Reloading systemd daemon"
        if ! systemctl daemon-reload; then
            log_warning "Failed to reload systemd daemon"
        fi
        
        # Reset any failed states
        if systemctl is-failed --quiet "${OTEL_SERVICE_NAME}.service" 2>/dev/null; then
            log_info "Resetting failed service state"
            systemctl reset-failed "${OTEL_SERVICE_NAME}.service" 2>/dev/null || true
        fi
    fi
    
    # Report what was removed
    if [[ "$existing_service" == "true" || "$existing_binary" == "true" || "$existing_config" == "true" || "$package_removed" == "true" ]]; then
        log_success "Existing installation cleaned up successfully"
    else
        log_info "No existing installation found"
    fi
    
    return 0
}

# Main installation flow
main() {
    # Parse command line arguments
    parse_args "$@"
    
    # Set up error handling
    trap otel_error ERR
    trap cleanup EXIT
    
    # Display OTEL header (interactive mode only)
    print_otel_header
    
    if [[ "$MODE" == "interactive" ]]; then
        otel_type "Initializing OpenTelemetry Installation Protocol..." 0.05
        echo
        echo -e "${CYAN}[OTEL]${NC} ${BOLD}Repository:${NC} ${YELLOW}https://github.com/open-telemetry/opentelemetry-collector-releases${NC}"
        echo -e "${CYAN}[OTEL]${NC} ${BOLD}Version:${NC} ${YELLOW}v${OTEL_VERSION}${NC}"
        echo -e "${CYAN}[OTEL]${NC} ${BOLD}Mode:${NC} ${YELLOW}${MODE}${NC}"
        echo -e "${CYAN}[OTEL]${NC} ${BOLD}Replace Config:${NC} ${YELLOW}${REPLACE_CONFIG}${NC}"
        echo
        sleep 1
    else
        # Basic mode: silent execution, only final result will be output
        :
    fi
    
    # Step 1: Check sudo permissions
    if [[ "$MODE" == "interactive" ]]; then
        otel_progress 1 8 "Checking system privileges" "running"
    fi
    if (( EUID != 0 )); then
        if [[ "$MODE" == "interactive" ]]; then
            otel_progress 1 8 "Running without sudo (some features may be limited)" "success"
        fi
        log_warning "Running without sudo. Some features may be limited."
    else
        if [[ "$MODE" == "interactive" ]]; then
            otel_progress 1 8 "System privileges verified" "success"
        fi
    fi
    if [[ "$MODE" == "interactive" ]]; then
        sleep 0.5
    fi
    
    # Step 2: Check and remove existing installation
    if [[ "$MODE" == "interactive" ]]; then
        otel_progress 2 8 "Checking for existing installation" "running"
    fi
    check_and_remove_existing
    if [[ "$MODE" == "interactive" ]]; then
        otel_progress 2 8 "Existing installation cleanup completed" "success"
        sleep 0.5
    fi
    
    # Step 3: Detect OS
    if [[ "$MODE" == "interactive" ]]; then
        otel_progress 3 8 "Scanning system environment" "running"
    fi
    if ! check_os; then
        if [[ "$MODE" == "interactive" ]]; then
            otel_progress 3 8 "Unsupported OS detected" "error"
        fi
        log_error "Unsupported operating system"
        otel_error
    fi
    if [[ "$MODE" == "interactive" ]]; then
        otel_progress 3 8 "Linux system detected: $os_name" "success"
        sleep 0.5
    fi
    
    # Step 4: Detect architecture
    if [[ "$MODE" == "interactive" ]]; then
        otel_progress 4 8 "Analyzing hardware architecture" "running"
    fi
    if ! check_architecture; then
        if [[ "$MODE" == "interactive" ]]; then
            otel_progress 4 8 "Unsupported architecture: $(uname -m)" "error"
        fi
        log_error "Unsupported architecture: $(uname -m)"
        otel_error
    fi
    if [[ "$MODE" == "interactive" ]]; then
        otel_progress 4 8 "Architecture: $arch_name, Package: $package_manager" "success"
        sleep 0.5
    fi
    
    # Step 5: Download OTEL Collector
    if [[ "$MODE" == "interactive" ]]; then
        otel_progress 5 8 "Downloading OTEL Collector" "running"
        echo
        echo -e "${CYAN}[OTEL]${NC} ${BOLD}Download Source:${NC} ${YELLOW}$download_url${NC}"
        echo -e "${CYAN}[OTEL]${NC} ${BOLD}Target File:${NC} ${YELLOW}$download_file${NC}"
        echo
    fi
    if ! download_otel; then
        if [[ "$MODE" == "interactive" ]]; then
            otel_progress 5 8 "Download failed" "error"
        fi
        otel_error
    fi
    if [[ "$MODE" == "interactive" ]]; then
        otel_progress 5 8 "Downloaded: $download_file" "success"
        sleep 0.5
    fi
    
    # Step 6: Create config file in current directory (only if replacing config)
    local step_num=6
    if [[ "$REPLACE_CONFIG" == "true" ]]; then
        if [[ "$MODE" == "interactive" ]]; then
            otel_progress $step_num 8 "Creating configuration file" "running"
        fi
        create_config
        if [[ "$MODE" == "interactive" ]]; then
            otel_progress $step_num 8 "Configuration file created" "success"
            sleep 0.5
        fi
        ((step_num++))
    fi
    
    # Step 7: Install OTEL Collector
    if [[ "$MODE" == "interactive" ]]; then
        otel_progress $step_num 8 "Installing OTEL Collector" "running"
    fi
    if ! install_otel; then
        if [[ "$MODE" == "interactive" ]]; then
            otel_progress $step_num 8 "Installation failed" "error"
        fi
        otel_error
    fi
    if [[ "$MODE" == "interactive" ]]; then
        otel_progress $step_num 8 "OTEL Collector installed successfully" "success"
        sleep 0.5
    fi
    ((step_num++))
    
    # Step 8: Replace config file with our custom one (only if replacing config)
    if [[ "$REPLACE_CONFIG" == "true" ]]; then
        if [[ "$MODE" == "interactive" ]]; then
            otel_progress $step_num 8 "Installing custom configuration" "running"
        fi
        if ! replace_config; then
            if [[ "$MODE" == "interactive" ]]; then
                otel_progress $step_num 8 "Config replacement failed" "error"
            fi
            otel_error
        fi
        if [[ "$MODE" == "interactive" ]]; then
            otel_progress $step_num 8 "Configuration installed successfully" "success"
            sleep 0.5
        fi
    fi
    
    # Check service status after installation
    if [[ "$MODE" == "interactive" ]]; then
        echo
        echo -e "${CYAN}[OTEL]${NC} ${BOLD}Checking service status...${NC}"
    fi
    if is_command_present systemctl; then
        if systemctl is-active --quiet "${OTEL_SERVICE_NAME}.service"; then
            log_success "Service is running (auto-started after installation)"
            service_already_running=true
        else
            log_info "Service is ready to start"
            service_already_running=false
        fi
    fi
    
    if [[ "$MODE" == "interactive" ]]; then
        echo
        otel_type "OpenTelemetry installation sequence complete..." 0.05
        sleep 1
    fi
    
    otel_success
    
    if [[ "$MODE" == "interactive" ]]; then
        echo
        echo -e "${CYAN}Next steps:${NC}"
        if [[ "${service_already_running:-false}" == "true" ]]; then
            echo -e "  1. Check status: ${BOLD}systemctl status ${OTEL_SERVICE_NAME}${NC} ${GREEN}(already running)${NC}"
            echo -e "  2. View logs: ${BOLD}journalctl -u ${OTEL_SERVICE_NAME} -f${NC}"
            echo -e "  3. Edit configuration: ${BOLD}${OTEL_CONFIG_FILE}${NC}"
            echo -e "  4. Restart after config changes: ${BOLD}systemctl restart ${OTEL_SERVICE_NAME}${NC}"
        else
            echo -e "  1. Start the service: ${BOLD}systemctl start ${OTEL_SERVICE_NAME}${NC}"
            echo -e "  2. Check status: ${BOLD}systemctl status ${OTEL_SERVICE_NAME}${NC}"
            echo -e "  3. View logs: ${BOLD}journalctl -u ${OTEL_SERVICE_NAME} -f${NC}"
            echo -e "  4. Edit configuration: ${BOLD}${OTEL_CONFIG_FILE}${NC}"
        fi
        echo
        echo -e "${YELLOW}Note:${NC} Downloaded file ${BOLD}${download_file}${NC} has been kept for your reference."
        echo
    fi
}

# Run the main installation
main "$@" 
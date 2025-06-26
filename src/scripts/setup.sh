#!/bin/bash
set -euo pipefail

# Get the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
UTILS_DIR="${ROOT_DIR}/utils"

# Source colors.sh if available
if [ -f "${UTILS_DIR}/colors.sh" ]; then
    . "${UTILS_DIR}/colors.sh"
else
    echo -e "\033[0;31m[!] ERROR: colors.sh not found in ${UTILS_DIR}\033[0m" >&2
    exit 1
fi

if [ -f "${UTILS_DIR}/logger.sh" ]; then
    source "${UTILS_DIR}/logger.sh"
    # Set up logging
    if ! setup_logging; then
        echo -e "${RED}[!] ERROR: Failed to set up logging. Exiting.${NC}" >&2
        exit 1
    fi
else
    # Fallback to basic logging if logger.sh is not available
    log_info() { echo -e "${GREEN}[*]${NC} $1"; }
    log_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
    log_error() { echo -e "${RED}[✗] ERROR:${NC} $1" >&2; exit 1; }
    log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
    log_debug() { [ "${DEBUG:-false}" = true ] && echo -e "${BLUE}[DEBUG]${NC} $1"; }
fi

# Global auto-confirm flag
AUTO_CONFIRM=false

# Log script start
log_info "=== Starting TuxTechCLI Setup ==="
log_info "Script directory: ${SCRIPT_DIR}"
log_info "User: $(whoami)"
log_info "Hostname: $(hostname -f 2>/dev/null || hostname)"
[ -n "${LOG_FILE:-}" ] && log_info "Log file: ${LOG_FILE}"

# Check if running as root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        log_error "This script must be run as root. Please use 'sudo'."
    fi
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install packages with progress and error handling
install_package() {
    local package_name="$1"
    local description="${2:-$package_name}"
    
    log_info "Installing $description..."
    if ! DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends $package_name 2>&1 | tee -a "${LOG_FILE:-/dev/null}"; then
        log_warning "Failed to install $description"
        return 1
    fi
    log_success "$description installed successfully"
    return 0
}

# Function to install pip packages
install_pip_package() {
    local package_name="$1"
    local description="${2:-$package_name}"
    
    log_info "Installing Python package $description..."
    if ! python3 -m pip install --upgrade $package_name 2>&1 | tee -a "${LOG_FILE:-/dev/null}"; then
        log_warning "Failed to install $description"
        return 1
    fi
    log_success "$description installed successfully"
    return 0
}

# Function to install snap packages
install_snap_package() {
    local package_name="$1"
    local description="${2:-$package_name}"
    
    log_info "Installing snap package $description..."
    if ! snap install $package_name 2>&1 | tee -a "${LOG_FILE:-/dev/null}"; then
        log_warning "Failed to install $description"
        return 1
    fi
    log_success "$description installed successfully"
    return 0
}

# Function to get user confirmation
confirm_install() {
    local message="$1"
    local default_choice="${2:-n}"
    
    # If auto-confirm is enabled, return true
    if [ "$AUTO_CONFIRM" = true ]; then
        log_info "Auto-confirming: $message"
        return 0
    fi
    
    while true; do
        if [ "$default_choice" = "y" ]; then
            read -p "$message [Y/n] " yn
            case $yn in
                [Yy]* | '' ) return 0;;
                [Nn]* ) return 1;;
                * ) log_warning "Please answer yes or no.";;
            esac
        else
            read -p "$message [y/N] " yn
            case $yn in
                [Yy]* ) return 0;;
                [Nn]* | '' ) return 1;;
                * ) log_warning "Please answer yes or no.";;
            esac
        fi
    done
}

# Function to install SSH
install_ssh() {
    if confirm_install "SSH tools (OpenSSH server and sshpass)" "y"; then
        log_info "Installing SSH tools..."
        install_package "openssh-server" "OpenSSH server"
        install_package "sshpass" "SSH password automation"
    fi
}

# Function to install text editors
install_editors() {
    if confirm_install "Text editors (nano, vim)" "y"; then
        log_info "Installing text editors..."
        install_package "nano vim" "Text editors (nano and vim)"
    fi
}

# Function to install network tools
install_network_tools() {
    if confirm_install "Network tools (traceroute, iperf3, net-tools, etc.)" "y"; then
        log_info "Installing network tools..."
        install_package "traceroute iperf3" "Network testing tools"
        install_package "net-tools" "Basic network tools"
        install_package "iproute2" "Advanced network tools"
        install_package "netcat" "Networking utility"
        install_package "telnet" "Telnet client"
        install_package "whois" "Whois client"
        install_package "dnsutils" "DNS utilities"
    fi
}

# Function to install monitoring and analysis tools
install_monitoring_tools() {
    if confirm_install "Monitoring tools (nmap, wireshark, tshark, termshark)" "y"; then
        log_info "Installing monitoring tools..."
        install_package "nmap" "Network scanning tool"
        install_package "wireshark" "Network protocol analyzer"
        install_package "tshark" "Command-line network analyzer"
        install_package "termshark" "Terminal UI for Wireshark"
    fi
}

# Function to install development tools
install_dev_tools() {
    if confirm_install "Development tools (Python, Node.js, Go, Rust)" "y"; then
        log_info "Installing development tools..."
        install_package "python3-pip" "Python package manager"
        install_package "python3-venv" "Python virtual environment"
        install_package "python3-dev" "Python development files"
        install_package "nodejs npm" "Node.js and npm"
        install_package "golang" "Go programming language"
        install_package "rustc cargo" "Rust programming language"
    fi
}

# Function to install additional utilities
install_utilities() {
    if confirm_install "Additional utilities (tree, jq, etc.)" "y"; then
        log_info "Installing additional utilities..."
        install_package "tree" "Directory tree viewer"
        install_package "jq" "JSON processor"
    fi
}

# Function to install Python packages
install_python_packages() {
    if confirm_install "Python packages (bpytop, httpie, black, etc.)" "y"; then
        log_info "Installing Python packages..."
        install_pip_package "bpytop" "System monitor"
        install_pip_package "httpie" "Modern command line HTTP client"
        install_pip_package "black" "Python code formatter"
        install_pip_package "isort" "Python import sorter"
        install_pip_package "flake8" "Python code linter"
    fi
}

# Function to install custom zsh configuration
install_custom_zshrc() {
    log_info "Setting up custom zsh configuration..."
    
    local ZSHRC_PATH="$HOME/.zshrc"
    local ZSHRC_BACKUP="${ZSHRC_PATH}.bak.$(date +%Y%m%d%H%M%S)"
    
    # The custom.zshrc is in the src/scripts directory
    local CUSTOM_ZSHRC="${ROOT_DIR}/scripts/custom.zshrc"
    
    # Debug: Show where we're looking
    log_debug "Looking for custom.zshrc at: $CUSTOM_ZSHRC"
    
    # Check if the custom zshrc exists and is readable
    if [ ! -f "$CUSTOM_ZSHRC" ] || [ ! -r "$CUSTOM_ZSHRC" ]; then
        log_warning "custom.zshrc not found at: $CUSTOM_ZSHRC"
        log_warning "A basic zsh configuration will be created instead."
        return 1
    fi
    
    log_info "Found custom.zshrc at: $CUSTOM_ZSHRC"
    
    # Create backup of existing .zshrc if it exists
    if [ -f "$ZSHRC_PATH" ]; then
        log_info "Backing up existing .zshrc to ${ZSHRC_BACKUP}"
        if cp "$ZSHRC_PATH" "${ZSHRC_BACKUP}"; then
            log_success "Backup created: ${ZSHRC_BACKUP}"
        else
            log_warning "Failed to create backup of ${ZSHRC_PATH}"
            log_info "Continuing without backup..."
        fi
    fi
    
    # Install the custom zshrc
    log_info "Installing custom zsh configuration from ${CUSTOM_ZSHRC}..."
    if cp "$CUSTOM_ZSHRC" "$ZSHRC_PATH"; then
        chmod 644 "$ZSHRC_PATH" 2>/dev/null || true  # Best effort to set permissions
        log_success "Custom zsh configuration installed at ${ZSHRC_PATH}"
        
        # Verify the file was copied successfully
        if [ -f "$ZSHRC_PATH" ] && [ -s "$ZSHRC_PATH" ]; then
            return 0
        else
            log_warning "Installation verification failed: ${ZSHRC_PATH} is empty or not accessible"
            return 1
        fi
    else
        log_warning "Failed to copy ${CUSTOM_ZSHRC} to ${ZSHRC_PATH}"
        return 1
    fi
    
    # Create a basic .zshrc if none exists
    if [ ! -f "$ZSHRC_PATH" ] || [ ! -s "$ZSHRC_PATH" ]; then
        log_info "Creating a basic .zshrc file..."
        cat > "$ZSHRC_PATH" << 'EOL'
# Basic zsh configuration
# Generated by TuxTechLab setup script

# Enable colors and change prompt
autoload -U colors && colors
PS1="%B%{$fg[red]%}[%{$fg[yellow]%}%n%{$fg[green]%}@%{$fg[blue]%}%M %{$fg[magenta]%}%~%{$fg[red]%}]%{$reset_color%}$%b "

# History in cache directory
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history

# Basic auto/tab complete
autoload -U compinit
zstyle ':completion:*' menu select
zmodload zsh/complist
compinit
_comp_options+=(globdots)

# Aliases
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'

# Add local bin to PATH if it exists
if [ -d "$HOME/.local/bin" ]; then
    export PATH="$HOME/.local/bin:$PATH"
fi
EOL
        
        if [ -f "$ZSHRC_PATH" ] && [ -s "$ZSHRC_PATH" ]; then
            log_success "Basic .zshrc created at ${ZSHRC_PATH}"
            return 0
        else
            log_warning "Failed to create basic .zshrc"
            return 1
        fi
    fi
    
    return 1  # If we get here, something went wrong
}

# Function to set zsh as default shell
set_zsh_default_shell() {
    local current_shell="$(getent passwd $USER | cut -d: -f7)"
    local zsh_path="$(command -v zsh)"
    
    if [ -z "$zsh_path" ]; then
        log_warning "zsh not found in PATH, cannot set as default shell"
        return 1
    fi
    
    if [ "$current_shell" != "$zsh_path" ]; then
        log_info "Setting zsh as default shell..."
        if chsh -s "$zsh_path" "$USER" 2>/dev/null; then
            log_success "Default shell changed to zsh. Please log out and back in for changes to take effect."
            return 0
        else
            log_warning "Failed to change default shell to zsh. You may need to run 'chsh' manually."
            return 1
        fi
    else
        log_info "zsh is already the default shell"
        return 0
    fi
}

# Function to configure shell
configure_shell() {
    local zsh_installed=true
    
    # Install zsh if not already installed
    if ! command_exists zsh; then
        log_info "Installing zsh..."
        if ! install_package "zsh" "Z shell"; then
            log_warning "Failed to install zsh, skipping shell configuration"
            return 1
        fi
    fi
    
    # Try to install zsh4humans if requested
    if confirm_install "Install zsh4humans (recommended)?" "y"; then
        log_info "Installing zsh4humans..."
        log_info "This will open an interactive installer. Please follow the prompts."
        
        # Run the installer (let it be interactive)
        if sh -c "$(curl -fsSL https://raw.githubusercontent.com/romkatv/zsh4humans/v5/install)"; then
            log_success "zsh4humans installation completed successfully"
            # zsh4humans handles its own .zshrc, so we don't need to do anything else
            return 0
        else
            log_warning "zsh4humans installation failed or was cancelled, falling back to basic zsh setup..."
        fi
    else
        log_info "Skipping zsh4humans installation as requested, setting up basic zsh..."
    fi
    
    # If we get here, either zsh4humans was not installed or installation failed
    # So we'll set up a basic zsh configuration
    
    # Install custom zshrc
    if ! install_custom_zshrc; then
        log_warning "Failed to install custom zshrc, creating a basic one..."
        # Create a minimal .zshrc if custom one couldn't be installed
        echo "# Basic zsh configuration\n# Generated by TuxTechLab setup script\n" > "$HOME/.zshrc"
    fi
    
    # Set zsh as default shell
    if ! set_zsh_default_shell; then
        log_warning "Failed to set zsh as default shell"
        return 1
    fi
    
    log_success "Basic shell configuration completed"
    return 0
}

# Main function
main() {
    local start_time
    start_time=$(date +%s)
    
    # Check if running as root
    if [ "$EUID" -ne 0 ]; then 
        log_error "Please run this script with sudo privileges"
        exit 1
    fi
    
    # Display script header
    log_info "=== TuxTechLab/TuxTechCli Setup Script ==="
    log_info "This script will install and configure various tools and settings."
    
    while true; do
        read -p "Do you want to auto-confirm all installation prompts? [y/N] " yn
        case $yn in
            [Yy]* ) 
                AUTO_CONFIRM=true
                log_info "Auto-confirm enabled. All installations will proceed automatically."
                break;;
            [Nn]* | '' ) 
                AUTO_CONFIRM=false
                log_info "Auto-confirm disabled. You will be prompted for each installation."
                break;;
            * ) echo "Please answer yes or no.";;
        esac
    done
    
    log_info "Starting setup process..."

    # Update package lists
    log_info "Updating package lists..."
    if ! apt-get update 2>&1 | tee -a "${LOG_FILE:-/dev/null}"; then
        log_warning "Failed to update some package lists"
    fi

    # Upgrade existing packages
    log_info "Upgrading installed packages..."
    if ! DEBIAN_FRONTEND=noninteractive apt-get upgrade -y 2>&1 | tee -a "${LOG_FILE:-/dev/null}"; then
        log_warning "Failed to upgrade some packages"
    fi

    # Install essential development tools
    install_package "build-essential" "Development tools"
    install_package "git" "Git version control"
    install_package "curl wget" "Download utilities"
    install_package "unzip zip" "Archive utilities"
    install_package "software-properties-common" "Software properties"

    # Install components
    install_ssh
    install_editors
    install_network_tools
    install_monitoring_tools
    install_dev_tools
    install_utilities
    install_python_packages
    
    # Configure shell
    configure_shell

    # Update MOTD
    if [ -f "/etc/motd" ]; then
        log_info "Updating MOTD..."
        echo 'ttl-motd' > /etc/motd
    fi

    # Calculate and log execution time
    local end_time
    local duration
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    
    log_success "=== TuxTechLab/TuxTechCli Setup completed in ${duration} seconds ==="
    log_info "Please log out and back in for all changes to take effect."
    
    # Display log file location
    local log_file=""
    local log_dir="${HOME}/.tuxtech/logs"
    local log_pattern="$(basename "$0" .sh)_*.log"
    
    # Try to find the most recent log file in the log directory
    if [ -d "$log_dir" ]; then
        log_file=$(find "$log_dir" -name "$log_pattern" -type f -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)
    fi
    
    # If not found, try other common locations
    if [ -z "$log_file" ] || [ ! -f "$log_file" ]; then
        for dir in "/var/log/tuxtech" "/tmp"; do
            if [ -d "$dir" ]; then
                local found=$(find "$dir" -name "$log_pattern" -type f -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)
                if [ -n "$found" ] && [ -f "$found" ]; then
                    log_file="$found"
                    break
                fi
            fi
        done
    fi
    
    # Display log file location if found
    if [ -n "$log_file" ] && [ -f "$log_file" ]; then
        log_success "Log file: ${log_file}"
    else
        log_warning "Log file not found. Check these locations for log files:"
        log_warning "  - ${log_dir}/${log_pattern}"
        log_warning "  - /var/log/tuxtech/${log_pattern}"
        log_warning "  - /tmp/${log_pattern}"
    fi
    
    return 0
}

# Run the main function
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
    exit $?
fi
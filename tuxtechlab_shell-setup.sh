#!/bin/bash

# Set colors for output
RED="\e[31m"
GREEN="\e[32m"
BLUE="\e[34m"
YELLOW="\e[33m"
RESET="\e[0m"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install packages with progress and error handling
install_package() {
    local package_name="$1"
    local description="$2"
    
    echo -e "\n${BLUE}[*] Installing $description...${RESET}"
    if sudo apt-get install -y $package_name; then
        echo -e "${GREEN}[✓] $description installed successfully${RESET}"
    else
        echo -e "${RED}[✗] Failed to install $description${RESET}"
        exit 1
    fi
}

# Function to install pip packages
install_pip_package() {
    local package_name="$1"
    local description="$2"
    
    echo -e "\n${BLUE}[*] Installing Python package $description...${RESET}"
    if python3 -m pip install $package_name; then
        echo -e "${GREEN}[✓] $description installed successfully${RESET}"
    else
        echo -e "${RED}[✗] Failed to install $description${RESET}"
        exit 1
    fi
}

# Function to install snap packages
install_snap_package() {
    local package_name="$1"
    local description="$2"
    
    echo -e "\n${BLUE}[*] Installing snap package $description...${RESET}"
    if sudo snap install $package_name; then
        echo -e "${GREEN}[✓] $description installed successfully${RESET}"
    else
        echo -e "${RED}[✗] Failed to install $description${RESET}"
        exit 1
    fi
}

# Function to get user confirmation
confirm_install() {
    local description="$1"
    local default_answer="$2"
    
    while true; do
        read -p "Install $description? (y/N): " yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) if [ "$default_answer" = "y" ]; then
                   return 0
               else
                   return 1
               fi;;
        esac
    done
}

# Function to install SSH
install_ssh() {
    if confirm_install "SSH tools (OpenSSH server and sshpass)" "y"; then
        echo -e "\n${BLUE}[*] Installing SSH tools...${RESET}"
        install_package "openssh-server" "OpenSSH server"
        install_package "sshpass" "SSH password automation"
    fi
}

# Function to install text editors
install_editors() {
    if confirm_install "Text editors (nano, vim, neovim)" "y"; then
        echo -e "\n${BLUE}[*] Installing text editors...${RESET}"
        install_package "nano vim" "Text editors (nano and vim)"
        install_package "neovim" "Advanced text editor"
    fi
}

# Function to install network tools
install_network_tools() {
    if confirm_install "Network tools (traceroute, iperf3, net-tools, etc.)" "y"; then
        echo -e "\n${BLUE}[*] Installing network tools...${RESET}"
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
    if confirm_install "Monitoring tools (htop, iotop, nethogs, etc.)" "y"; then
        echo -e "\n${BLUE}[*] Installing monitoring tools...${RESET}"
        install_package "htop" "Interactive process viewer"
        install_package "iotop" "IO usage monitor"
        install_package "iftop" "Network bandwidth monitor"
        install_package "nethogs" "Per-process bandwidth monitor"
        install_package "nmap" "Network scanning tool"
        install_package "wireshark" "Network protocol analyzer"
        install_package "tshark" "Command-line network analyzer"
        install_package "termshark" "Terminal UI for Wireshark"
    fi
}

# Function to install development tools
install_dev_tools() {
    if confirm_install "Development tools (Python, Node.js, Go, Rust)" "y"; then
        echo -e "\n${BLUE}[*] Installing development tools...${RESET}"
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
    if confirm_install "Additional utilities (tree, fzf, ripgrep, etc.)" "y"; then
        echo -e "\n${BLUE}[*] Installing additional utilities...${RESET}"
        install_package "tree" "Directory tree viewer"
        install_package "lynx" "Text-based web browser"
        install_package "jq" "JSON processor"
        install_package "fzf" "Fuzzy finder"
        install_package "ripgrep" "Fast text search"
        install_package "fd-find" "Smart file finder"
        install_package "bat" "Cat with syntax highlighting"
        install_package "exa" "Modern ls replacement"
        install_package "zellij" "Terminal workspace manager"
    fi
}

# Function to install Python packages
install_python_packages() {
    if confirm_install "Python packages (bpytop, httpie, black, etc.)" "y"; then
        echo -e "\n${BLUE}[*] Installing Python packages...${RESET}"
        install_pip_package "bpytop" "System monitor"
        install_pip_package "httpie" "Modern command line HTTP client"
        install_pip_package "black" "Python code formatter"
        install_pip_package "isort" "Python import sorter"
        install_pip_package "flake8" "Python code linter"
    fi
}

# Function to install snap packages
install_snap_packages() {
    if command_exists snap && confirm_install "Snap packages (Postman, Insomnia, DBeaver)" "y"; then
        echo -e "\n${BLUE}[*] Installing snap packages...${RESET}"
        install_snap_package "postman" "API development environment"
        install_snap_package "insomnia" "Alternative API client"
        install_snap_package "dbeaver-ce" "Database management tool"
    fi
}

# Function to install GPG Key Manager
install_gpg_key_manager() {
    if confirm_install "GPG Key Manager (from local repo)" "y"; then
        echo -e "\n${BLUE}[*] Installing GPG Key Manager...${RESET}"
        # Install from local repository
        cd $(dirname "$0")
        if [ -f "setup.py" ]; then
            python3 setup.py install
            echo -e "${GREEN}[✓] GPG Key Manager installed successfully${RESET}"
        else
            echo -e "${RED}[✗] Could not find setup.py in the repository${RESET}"
            echo -e "${YELLOW}[*] Skipping GPG Key Manager installation${RESET}"
        fi
    fi
}

# Function to configure shell
configure_shell() {
    if confirm_install "Shell configuration (aliases and settings)" "y"; then
        echo -e "\n${BLUE}[*] Configuring shell...${RESET}"
        if [ ! -f "$HOME/.bash_aliases" ]; then
            touch "$HOME/.bash_aliases"
            echo "# TuxTechLab Aliases" >> "$HOME/.bash_aliases"
            echo "alias ll='exa -l --git'" >> "$HOME/.bash_aliases"
            echo "alias grep='grep --color=auto'" >> "$HOME/.bash_aliases"
            echo "alias ls='exa --color=always'" >> "$HOME/.bash_aliases"
            echo "alias cat='bat'" >> "$HOME/.bash_aliases"
            echo "alias vi='nvim'" >> "$HOME/.bash_aliases"
        fi
    fi
}

# Main function
main() {
    # Check if running as root
    if [ "$EUID" -ne 0 ]; then 
        echo -e "${RED}[✗] Please run this script with sudo privileges${RESET}"
        exit 1
    fi

    echo -e "${BLUE}[*] TuxTechLab Shell Setup Script${RESET}"
    echo -e "${BLUE}[*] Starting system update and upgrade...${RESET}"

    # Update package lists
    if ! sudo apt-get update; then
        echo -e "${RED}[✗] Failed to update package lists${RESET}"
        exit 1
    fi

    # Upgrade existing packages
    if ! sudo apt-get upgrade -y; then
        echo -e "${RED}[✗] Failed to upgrade packages${RESET}"
        exit 1
    fi

    # Install essential development tools
    install_package "build-essential" "Development tools"
    install_package "git" "Git version control"
    install_package "curl wget" "Download utilities"
    install_package "unzip zip" "Archive utilities"
    install_package "software-properties-common" "Software properties"

    # Install SSH
    install_ssh
    
    # Install text editors
    install_editors
    
    # Install network tools
    install_network_tools
    
    # Install monitoring tools
    install_monitoring_tools
    
    # Install development tools
    install_dev_tools
    
    # Install additional utilities
    install_utilities
    
    # Install Python packages
    install_python_packages
    
    # Install snap packages
    install_snap_packages
    
    # Install GPG Key Manager
    install_gpg_key_manager
    
    # Configure shell
    configure_shell

    # Update MOTD
    if [ -f "/etc/motd" ]; then
        echo "" > /etc/motd
    fi

    echo -e "${GREEN}\n[✓] Setup completed successfully!${RESET}"
    echo -e "${BLUE}[*] Please log out and back in for all changes to take effect.${RESET}"
}

# Execute main function
main

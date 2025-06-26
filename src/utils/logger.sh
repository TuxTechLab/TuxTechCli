#!/bin/bash
# Script to execute and log another script with full output capture
# Usage: source logger.sh
#       log_script [options] script_to_run [script_arguments]
# Or:   ./logger.sh [options] script_to_run [script_arguments]
#
# Log levels:
#   DEBUG:   Detailed debug information (blue)
#   INFO:    General information (green)
#   WARNING: Warning messages (yellow)
#   ERROR:   Error conditions (red)
#   FATAL:   Critical errors (red with white background)

set -euo pipefail

# Log level constants
readonly LOG_LEVEL_DEBUG=0
readonly LOG_LEVEL_INFO=1
readonly LOG_LEVEL_WARNING=2
readonly LOG_LEVEL_ERROR=3
readonly LOG_LEVEL_FATAL=4

# Default log level (can be overridden by LOG_LEVEL environment variable)
LOG_LEVEL=${LOG_LEVEL:-$LOG_LEVEL_INFO}

# Get the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source colors.sh if it exists
if [ -f "${SCRIPT_DIR}/colors.sh" ]; then
    source "${SCRIPT_DIR}/colors.sh"
    # Use color variables from colors.sh
    # Define aliases for backward compatibility
    RED="$Red"
    GREEN="$Green"
    YELLOW="$Yellow"
    BLUE="$Blue"
    PURPLE="$Purple"
    CYAN="$Cyan"
    WHITE="$White"
    NC="$NC"  # No Color
else
    # Fallback colors if colors.sh is not available
    echo "WARNING: colors.sh not found, using basic colors" >&2
    NC='\033[0m' # No Color
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    PURPLE='\033[0;35m'
    CYAN='\033[0;36m'
    WHITE='\033[0;37m'
    
    # Define color functions for compatibility
    print_color() {
        local color="$1"
        local message="${@:2}"
        echo -e "${!color}${message}${NC}"
    }
fi

# Function to ensure log directory exists with correct permissions
ensure_log_dir() {
    local dir="$1"
    # Create directory if it doesn't exist
    mkdir -p "$dir"
    # Set permissions to 744 (rwxr--r--)
    chmod 744 "$dir"
    # Ensure the directory is owned by the current user
    if [ "$(id -u)" -eq 0 ]; then
        chown -R "${SUDO_USER:-$USER}" "$dir" || true
    fi
}

# Default values
TUXTECH_DIR="${HOME}/.tuxtechlab"
LOG_DIR="${TUXTECH_DIR}/logs"
LOG_FILE=""
MAX_SIZE=5  # in MB
MAX_BACKUPS=10
PYTHON_LOGGER="${SCRIPT_DIR}/logger.py"

# Log file for the current session
CURRENT_LOG_FILE=""

# Function to get current timestamp in ISO 8601 format with milliseconds
log_timestamp() {
    date '+%Y-%m-%dT%H:%M:%S.%3N%z'
}

# Function to log a message with specified level and color
log_message() {
    local level=$1
    local color=$2
    local level_str=$3
    local message="${@:4}"
    local timestamp=$(log_timestamp)
    
    # Log to console with colors
    if [ -t 1 ]; then
        echo -e "${color}[${timestamp}] [${level_str}] ${message}${NC}"
    else
        echo "[${timestamp}] [${level_str}] ${message}"
    fi
    
    # Log to file without colors
    if [ -n "$CURRENT_LOG_FILE" ]; then
        echo "[${timestamp}] [${level_str}] ${message}" >> "$CURRENT_LOG_FILE"
    fi
}

# Log level functions
log_debug() {
    [ $LOG_LEVEL -le $LOG_LEVEL_DEBUG ] && log_message $LOG_LEVEL_DEBUG "$BLUE" "DEBUG" "$@"
}

log_info() {
    [ $LOG_LEVEL -le $LOG_LEVEL_INFO ] && log_message $LOG_LEVEL_INFO "$GREEN" "INFO" "$@"
}

log_warning() {
    [ $LOG_LEVEL -le $LOG_LEVEL_WARNING ] && log_message $LOG_LEVEL_WARNING "$YELLOW" "WARN" "$@"
}

log_error() {
    [ $LOG_LEVEL -le $LOG_LEVEL_ERROR ] && log_message $LOG_LEVEL_ERROR "$RED" "ERROR" "$@"
}

log_fatal() {
    log_message $LOG_LEVEL_FATAL "${RED}${WHITE_BG}" "FATAL" "$@"
    exit 1
}

log_success() {
    log_message $LOG_LEVEL_INFO "$BBlue" "SUCCESS" "$@"
}

# Function to set up logging
setup_logging() {
    # Ensure log directory exists with correct permissions
    if ! ensure_log_dir "$LOG_DIR"; then
        echo "ERROR: Failed to create log directory: $LOG_DIR" >&2
        return 1
    fi
    
    # Set up log file with timestamp
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    LOG_FILE="${LOG_DIR}/tuxtech_${timestamp}.log"
    
    # Create log file with correct permissions
    if ! touch "$LOG_FILE" || ! chmod 600 "$LOG_FILE"; then
        echo "ERROR: Failed to create log file: $LOG_FILE" >&2
        return 1
    fi
    
    # Log initialization message
    log_info "=== Logging initialized ==="
    log_info "Log file: $LOG_FILE"
    
    # Set up trap to ensure cleanup on exit
    trap cleanup_on_exit EXIT
    
    return 0
}

# Ensure default log directory exists with correct permissions
ensure_log_dir "$LOG_DIR"

# Export all functions at the end of the file
export -f log_debug log_info log_warning log_error log_fatal log_success log_message setup_logging ensure_log_dir

# Function to show help
show_help() {
    echo "Usage: ${FUNCNAME[1]:-$0} [options] script_to_run [script_arguments]"
    echo "Options:"
    echo "  --log-dir=DIR      Directory to store log files (default: ~/.tuxtechlab/logs)"
    echo "  --log-file=FILE    Full path to log file (overrides --log-dir)"
    echo "  --max-size=SIZE    Maximum log file size in MB (default: 5)"
    echo "  --max-backups=N    Maximum number of backup logs to keep (default: 5)"
    echo "  --help             Show this help message"
    echo ""
    echo "When sourced, provides 'log_script' function. When executed, runs as a script."
}

# Function to rotate log files if they exceed max size
rotate_logs() {
    local log_dir="$1"
    local max_backups=${2:-10}
    local max_size_mb=${3:-5}  # Default 5MB
    
    # Ensure log directory exists
    mkdir -p "$log_dir"
    
    # Find all log files
    while IFS= read -r log_file; do
        # Skip if file doesn't exist or is empty
        [ ! -f "$log_file" ] && continue
        
        # Get file size in MB
        local size_mb=$(($(stat -c%s "$log_file" 2>/dev/null || echo 0) / 1024 / 1024))
        
        # If file is larger than max size, rotate it
        if [ $size_mb -ge $max_size_mb ]; then
            log_info "Rotating log file: $log_file (size: ${size_mb}MB)"
            
            # Create backup with timestamp
            local timestamp=$(date +%Y%m%d_%H%M%S)
            local backup_file="${log_file}.${timestamp}"
            
            # Move current log to backup
            mv "$log_file" "$backup_file"
            
            # Compress old backups in background
            gzip "$backup_file" &
        fi
    done < <(find "$log_dir" -maxdepth 1 -type f -name '*.log' ! -name '*.gz')
    
    # Clean up old backups
    local backup_count=$(find "$log_dir" -name '*.log.*.gz' | wc -l)
    if [ $backup_count -gt $max_backups ]; then
        log_info "Cleaning up old log backups (keeping $max_backups)"
        find "$log_dir" -name '*.log.*.gz' -printf '%T@ %p\n' | \
            sort -n | head -n -$max_backups | cut -d' ' -f2- | xargs -r rm -f
    fi
}

# Function to clean up on exit
cleanup_on_exit() {
    local exit_code=$?
    local log_file="${1:-/dev/null}"  # Default to /dev/null if no log file provided
    
    # Only try to write to log file if it's writable and not /dev/null
    if [ -w "$log_file" ] && [ "$log_file" != "/dev/null" ]; then
        print_color "YELLOW" "\n[$(date '+%Y-%m-%d %H:%M:%S')] Script execution completed with exit code: ${exit_code}" | \
            tee -a "$log_file" >&2
    else
        print_color "YELLOW" "\n[$(date '+%Y-%m-%d %H:%M:%S')] Script execution completed with exit code: ${exit_code}" >&2
    fi
    
    return $exit_code
}

# Main logging function
log_script() {
    local SCRIPT_TO_RUN=""
    local SCRIPT_ARGS=()
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --log-dir=*)
                LOG_DIR="${1#*=}"
                shift
                ;;
            --log-file=*)
                LOG_FILE="${1#*=}"
                shift
                ;;
            --max-size=*)
                MAX_SIZE="${1#*=}"
                shift
                ;;
            --max-backups=*)
                MAX_BACKUPS="${1#*=}"
                shift
                ;;
            --help)
                show_help
                return 0
                ;;
            --*)
                log_error "Unknown option: $1"
                show_help
                return 1
                ;;
            *)
                # First non-option argument is the script to run
                if [[ -z "${SCRIPT_TO_RUN}" ]]; then
                    SCRIPT_TO_RUN="$1"
                else
                    # All other arguments are passed to the script
                    SCRIPT_ARGS+=("$1")
                fi
                shift
                ;;
        esac
    done
    
    # Show help if no script provided
    if [[ -z "${SCRIPT_TO_RUN}" ]]; then
        show_help
        return 1
    fi
    
    # Resolve full path to script
    if [[ ! "$SCRIPT_TO_RUN" =~ ^/ ]]; then
        SCRIPT_TO_RUN="$(pwd)/$SCRIPT_TO_RUN"
    fi
    
    # Set default log file if not specified
    if [[ -z "$LOG_FILE" ]]; then
        LOG_FILE="${LOG_DIR}/$(basename "${SCRIPT_TO_RUN%.*}")_$(date +%Y%m%d_%H%M%S).log"
    fi
    
    # Ensure log directory exists with correct permissions
    ensure_log_dir "$(dirname "$LOG_FILE")"
    
    # Set the current log file for the logging functions
    CURRENT_LOG_FILE="$LOG_FILE"
    
    log_info "Starting script: $SCRIPT_TO_RUN"
    log_info "Log file: $LOG_FILE"
    log_info "Arguments: ${SCRIPT_ARGS[*]}"
    log_info "Hostname: $(hostname)"
    log_info "User: $(whoami)"
    log_info "Working directory: $(pwd)"
    
    # Set up trap to ensure cleanup runs on exit
    trap 'cleanup_on_exit "$LOG_FILE"' EXIT
    
    # Log script start
    # Execute the script with output captured and logged
    {
        # Execute the script and capture output
        SCRIPT_START_TIME=$(date +%s)
        SCRIPT_PID=$$
        
        # Set up trap for cleanup
        trap cleanup EXIT
        
        log_info "Executing: $SCRIPT_TO_RUN ${SCRIPT_ARGS[*]}"
        log_debug "Environment:\n$(env | sort)"
        
        # Execute the script with arguments
        if [ -x "$SCRIPT_TO_RUN" ]; then
            # If script is executable, run it directly
            "$SCRIPT_TO_RUN" "${SCRIPT_ARGS[@]}" 2>&1 | tee -a "$LOG_FILE"
        else
            # Otherwise, try to execute with bash
            bash "$SCRIPT_TO_RUN" "${SCRIPT_ARGS[@]}" 2>&1 | tee -a "$LOG_FILE"
        fi
        
        # Capture the exit code
        EXIT_CODE=${PIPESTATUS[0]}
        
        # Log the exit code
        if [ $EXIT_CODE -eq 0 ]; then
            log_info "Script execution completed successfully"
        else
            log_error "Script execution failed with exit code: $EXIT_CODE"
        fi
        
        # Explicitly call cleanup in case the trap doesn't fire
        cleanup
        
        # Return the script's exit code
        return $EXIT_CODE
    } 2>&1 | "$PYTHON_LOGGER" --log-file="$LOG_FILE" --max-size=$((MAX_SIZE * 1024 * 1024)) --max-backups=$MAX_BACKUPS
    
    # Capture the exit code from the pipeline
    return ${PIPESTATUS[0]}
}

# If the script is being executed (not sourced), run the log_script function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --log-dir=*)
                LOG_DIR="${1#*=}"
                shift
                ;;
            --log-file=*)
                LOG_FILE="${1#*=}"
                shift
                ;;
            --max-size=*)
                MAX_SIZE="${1#*=}"
                shift
                ;;
            --max-backups=*)
                MAX_BACKUPS="${1#*=}"
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            --*)
                print_color "RED" "Error: Unknown option $1" >&2
                show_help
                exit 1
                ;;
            *)
                # First non-option argument is the script to run
                if [[ -z "${SCRIPT_TO_RUN:-}" ]]; then
                    SCRIPT_TO_RUN="$1"
                else
                    # All other arguments are passed to the script
                    SCRIPT_ARGS+=("$1")
                fi
                shift
                ;;
        esac
    done

    # Show help if no script provided
    if [[ -z "${SCRIPT_TO_RUN:-}" ]]; then
        show_help
        exit 1
    fi

    # Resolve full path to script
    if [[ ! "$SCRIPT_TO_RUN" =~ ^/ ]]; then
        SCRIPT_TO_RUN="$(pwd)/$SCRIPT_TO_RUN"
    fi

    # Set default log file if not specified
    if [[ -z "$LOG_FILE" ]]; then
        LOG_FILE="${LOG_DIR}/$(basename "${SCRIPT_TO_RUN%.*}")_$(date +%Y%m%d_%H%M%S).log"
    fi

    # Ensure log directory exists with correct permissions
    ensure_log_dir "$(dirname "$LOG_FILE")"
    
    # Call the log_script function with the parsed arguments
    log_script "${SCRIPT_TO_RUN}" "${SCRIPT_ARGS[@]-}"
    exit $?
fi

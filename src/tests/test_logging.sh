#!/bin/bash

# Exit on error
set -e

# Create a cleanup function
cleanup() {
    if [ -f "$TEMP_LOG" ]; then
        echo "Cleaning up temporary log file: $TEMP_LOG"
        rm -f "$TEMP_LOG"
    fi
}

# Set up trap to ensure cleanup runs on script exit
trap cleanup EXIT

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTILS_DIR="$(cd "${SCRIPT_DIR}/../utils" && pwd)"

# Create a temporary log file in the current directory
TEMP_LOG="${SCRIPT_DIR}/test.log"
echo "Using temporary log file: $TEMP_LOG"
# Ensure the file exists and is empty
: > "$TEMP_LOG"

# Source the colors first
if [ -f "${UTILS_DIR}/colors.sh" ]; then
    source "${UTILS_DIR}/colors.sh"
else
    echo "Error: colors.sh not found at ${UTILS_DIR}/colors.sh" >&2
    exit 1
fi

# Set up log directory and file
LOG_DIR="${HOME}/.tuxtechlab/tuxtechcli/logs"
mkdir -p "${LOG_DIR}"
LOG_FILE="${LOG_DIR}/test_$(date +%Y%m%d_%H%M%S).log"

# Export required variables for the logger
export LOG_LEVEL=0  # DEBUG level
export LOG_FILE="$TEMP_LOG"  # Use our temporary log file

# Now source the logger
if [ -f "${UTILS_DIR}/logger.sh" ]; then
    source "${UTILS_DIR}/logger.sh"
else
    echo "Error: logger.sh not found at ${UTILS_DIR}/logger.sh" >&2
    exit 1
fi

# Test logging functions
echo "=== Testing logger with colors ==="
log_debug "This is a debug message"
log_info "This is an info message"
log_warning "This is a warning message"
log_error "This is an error message"
log_success "This is a success message"

# Test colors
echo -e "\n=== Testing colors ==="
echo -e "${Red}Red text${NC}"
echo -e "${Green}Green text${NC}"
echo -e "${Yellow}Yellow text${NC}"
echo -e "${Blue}Blue text${NC}"

# Display the log file content
echo -e "\n=== Log File Content ==="
if [ -f "$LOG_FILE" ] && [ -s "$LOG_FILE" ]; then
    echo -e "\nLog file location: $LOG_FILE"
    echo "Log file size: $(wc -l < "$LOG_FILE") lines"
else
    echo "Warning: Log file not created or deleted."
    # ls -la "$(dirname "$LOG_FILE")" || true
fi

echo -e "\n=== Test completed successfully ==="

#!/bin/bash

# Simple test script for logger and colors

echo "Testing logger and colors..."

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTILS_DIR="${SCRIPT_DIR}/../utils"

# Source the logger and colors
if [ -f "${UTILS_DIR}/colors.sh" ]; then
    source "${UTILS_DIR}/colors.sh"
else
    echo "Error: colors.sh not found at ${UTILS_DIR}/colors.sh"
    exit 1
fi

if [ -f "${UTILS_DIR}/logger.sh" ]; then
    source "${UTILS_DIR}/logger.sh"
else
    echo "Error: logger.sh not found at ${UTILS_DIR}/logger.sh"
    exit 1
fi

# Test colors using the print_color function from colors.sh
print_color "Red" "This is red text"
print_color "Green" "This is green text"
print_color "Yellow" "This is yellow text"
print_color "Blue" "This is blue text"

# Test logging
echo "Testing logging functions..."
log_debug "This is a debug message"
log_info "This is an info message"
log_warning "This is a warning message"
log_error "This is an error message"  # This might return non-zero
log_success "This is a success message"

echo "Test complete!"

# Always exit with success status
exit 0

#!/bin/bash

# Simple test script to verify colors are working

echo "=== Color Test Script ==="

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COLORS_FILE="${SCRIPT_DIR}/utils/colors.sh"

# Check if colors.sh exists
if [ ! -f "$COLORS_FILE" ]; then
    echo "Error: colors.sh not found at $COLORS_FILE"
    exit 1
fi

# Source the colors file
echo "Sourcing colors from: $COLORS_FILE"
source "$COLORS_FILE"

# Check if we got any color variables
echo -e "\n=== Checking Color Variables ==="

# Test if we can access the color variables
if [ -z "${Red:-}" ] || [ -z "${Green:-}" ] || [ -z "${NC:-}" ]; then
    echo "Error: Required color variables not found"
    echo "Red=${Red:-Not set}, Green=${Green:-Not set}, NC=${NC:-Not set}"
    
    # Try direct assignment as a fallback
    echo -e "\nTrying direct color assignment..."
    NC='\033[0m'
    Red='\033[0;31m'
    Green='\033[0;32m'
    Yellow='\033[0;33m'
    Blue='\033[0;34m'
    
    if [ -z "$Red" ] || [ -z "$NC" ]; then
        echo "Direct assignment also failed. Terminal might not support colors."
        exit 1
    else
        echo "Using direct color assignment"
    fi
else
    echo "Color variables found and set correctly"
fi

# Test basic colors
echo -e "\n=== Testing Basic Colors ==="
colors=("$Red" "$Green" "$Yellow" "$Blue" "$Purple" "$Cyan")
color_names=("Red" "Green" "Yellow" "Blue" "Purple" "Cyan")

for i in "${!colors[@]}"; do
    echo -e "${colors[$i]}This is ${color_names[$i]} text$NC"
done

# Test bold colors if available
if [ -n "${BRed:-}" ] && [ -n "${BGreen:-}" ]; then
    echo -e "\n=== Testing Bold Colors ==="
    bold_colors=("$BRed" "$BGreen" "$BYellow" "$BBlue" "$BPurple" "$BCyan")
    bold_names=("BRed" "BGreen" "BYellow" "BBlue" "BPurple" "BCyan")
    
    for i in "${!bold_colors[@]}"; do
        echo -e "${bold_colors[$i]}This is ${bold_names[$i]} text$NC"
    done
else
    echo -e "\n=== Bold colors not available ==="
    echo -e "Bold color variables not found. Using regular colors for bold text."
    for color in "$Red" "$Green" "$Yellow" "$Blue" "$Purple" "$Cyan"; do
        echo -e "$color*** This would be bold text ***$NC"
    done
fi

# Test with printf
echo -e "\n=== Testing with printf ==="
printf "%b\n" "${Red}This is red text using printf${NC}"
printf "%b\n" "${Green}This is green text using printf${NC}"

# Test with raw color codes
echo -e "\n=== Testing Raw ANSI Codes ==="
echo -e "\033[0;31mThis is red using raw code\033[0m"
echo -e "\033[0;32mThis is green using raw code\033[0m"
# Show terminal info
echo -e "\n=== Terminal Information ==="
echo "TERM: ${TERM:-Not set}"
echo "SHELL: ${SHELL:-Not set}"

# Check if we're in WSL
if grep -qEi "microsoft|WSL" /proc/version 2>/dev/null; then
    echo "Running in WSL (Windows Subsystem for Linux)"
    if [ -n "$WT_SESSION" ]; then
        echo "Windows Terminal detected"
    fi
fi

echo -e "\n=== Test Complete ==="
echo "If you don't see colors, try these solutions:"
echo "1. Use a different terminal emulator (like Windows Terminal)"
echo "2. Make sure your TERM environment variable is set correctly"
echo "3. Try running with: bash -i $0"
echo "4. Check if your terminal supports 256 colors with: tput colors"

#!/bin/bash

# Quick test script to verify basic color functionality

echo "=== Terminal Color Test ==="
# Check if we're in a terminal that supports colors
if [ -t 1 ]; then
    echo "Terminal supports colors"
else
    echo "Warning: Not a terminal or doesn't support colors"
    echo "This script will continue but colors might not display correctly."
fi

# Test basic colors using raw ANSI codes
echo -e "\nTesting basic colors:"
echo -e "\033[0;31mRed text\033[0m"
echo -e "\033[0;32mGreen text\033[0m"
echo -e "\033[0;33mYellow text\033[0m"
echo -e "\033[0;34mBlue text\033[0m"

# Test bold colors
echo -e "Testing bold colors:"
echo -e "\033[1;31mBold red text\033[0m"
echo -e "\033[1;32mBold green text\033[0m"

# Test using printf which is more reliable
echo -e "\nTesting with printf (more reliable):"
printf "%b\n" "\033[0;31mRed text with printf\033[0m"
printf "%b\n" "\033[0;32mGreen text with printf\033[0m"

# Test if colors are working
if [ -n "$TERM" ] && [ "$TERM" != "dumb" ]; then
    echo -e "\n=== Test Results ==="
    echo -e "If you see colored text above, your terminal supports colors."
    echo -e "If you don't see colors, try one of these solutions:"
    echo "1. Use a different terminal emulator"
    echo "2. Make sure your TERM environment variable is set correctly"
    echo "3. Try running with: bash -i script.sh"
    echo -e "4. Check if your terminal supports 256 colors with: echo \$TERM"
else
    echo "\n=== Test Results ==="
    echo "Your terminal doesn't appear to support colors (TERM=$TERM)"
    echo "Try running this script in a different terminal."
fi

echo -e "\n=== Test Complete ==="

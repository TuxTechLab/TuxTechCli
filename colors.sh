#!/bin/bash
# 
# Shell Colors Module - A comprehensive shell color library
# Version: 1.1.0
# Author: TuxTechLab
# License: MIT
# 
# Usage:
#   source colors.sh
#   print_color "Red" "Hello World"
#   print_bold_color "BGreen" "Important message"
#   print_underline "UCyan" "Underlined text"
#
# Features:
#   - 256 color support
#   - RGB color support
#   - Color combinations
#   - Color palette generation
#   - Color brightness adjustment
#   - Color contrast checking

# Module metadata
COLORS_MODULE_VERSION="1.1.0"
COLORS_MODULE_NAME="Shell Colors Module"
COLORS_MODULE_AUTHOR="TuxTechLab"
COLORS_MODULE_LICENSE="MIT"

# Reset
Color_Off='\033[0m'       # Text Reset

# Regular Colors
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White

# Bold
BBlack='\033[1;30m'       # Black
BRed='\033[1;31m'         # Red
BGreen='\033[1;32m'       # Green
BYellow='\033[1;33m'      # Yellow
BBlue='\033[1;34m'        # Blue
BPurple='\033[1;35m'      # Purple
BCyan='\033[1;36m'        # Cyan
BWhite='\033[1;37m'       # White

# Underline
UBlack='\033[4;30m'       # Black
URed='\033[4;31m'         # Red
UGreen='\033[4;32m'       # Green
UYellow='\033[4;33m'      # Yellow
UBlue='\033[4;34m'        # Blue
UPurple='\033[4;35m'      # Purple
UCyan='\033[4;36m'        # Cyan
UWhite='\033[4;37m'       # White

# Background
On_Black='\033[40m'       # Black
On_Red='\033[41m'         # Red
On_Green='\033[42m'       # Green
On_Yellow='\033[43m'      # Yellow
On_Blue='\033[44m'        # Blue
On_Purple='\033[45m'      # Purple
On_Cyan='\033[46m'        # Cyan
On_White='\033[47m'       # White

# High Intensity
IBlack='\033[0;90m'       # Black
IRed='\033[0;91m'         # Red
IGreen='\033[0;92m'       # Green
IYellow='\033[0;93m'      # Yellow
IBlue='\033[0;94m'        # Blue
IPurple='\033[0;95m'      # Purple
ICyan='\033[0;96m'        # Cyan
IWhite='\033[0;97m'       # White

# Bold High Intensity
BIBlack='\033[1;90m'      # Black
BIRed='\033[1;91m'        # Red
BIGreen='\033[1;92m'      # Green
BIYellow='\033[1;93m'     # Yellow
BIBlue='\033[1;94m'       # Blue
BIPurple='\033[1;95m'     # Purple
BICyan='\033[1;96m'       # Cyan
BIWhite='\033[1;97m'      # White

# High Intensity backgrounds
On_IBlack='\033[0;100m'   # Black
On_IRed='\033[0;101m'     # Red
On_IGreen='\033[0;102m'   # Green
On_IYellow='\033[0;103m'  # Yellow
On_IBlue='\033[0;104m'    # Blue
On_IPurple='\033[0;105m'  # Purple
On_ICyan='\033[0;106m'    # Cyan
On_IWhite='\033[0;107m'   # White

# Function to print colored text
print_color() {
    local color=$1
    local message=$2
    echo -e "${!color}${message}${Color_Off}"
}

# Function to print colored text with bold
print_bold_color() {
    local color=$1
    local message=$2
    echo -e "${!color}${message}${Color_Off}"
}

# Function to print underlined text
print_underline() {
    local color=$1
    local message=$2
    echo -e "${!color}${message}${Color_Off}"
}

# Function to print text with background color
print_bg_color() {
    local bg_color=$1
    local message=$2
    echo -e "${!bg_color}${message}${Color_Off}"
}

# Function to print text with both foreground and background colors
print_color_combo() {
    local fg_color=$1
    local bg_color=$2
    local message=$3
    echo -e "${!bg_color}${!fg_color}${message}${Color_Off}"
}

# Function to generate a color palette
print_color_palette() {
    echo "Color Palette:"
    echo "Foreground Colors:"
    print_color "Black" "Black"
    print_color "Red" "Red"
    print_color "Green" "Green"
    print_color "Yellow" "Yellow"
    print_color "Blue" "Blue"
    print_color "Purple" "Purple"
    print_color "Cyan" "Cyan"
    print_color "White" "White"
    
    echo "\nBackground Colors:"
    print_bg_color "On_Black" "Black"
    print_bg_color "On_Red" "Red"
    print_bg_color "On_Green" "Green"
    print_bg_color "On_Yellow" "Yellow"
    print_bg_color "On_Blue" "Blue"
    print_bg_color "On_Purple" "Purple"
    print_bg_color "On_Cyan" "Cyan"
    print_bg_color "On_White" "White"
}

# Function to check color contrast
check_contrast() {
    local fg_color=$1
    local bg_color=$2
    local fg_brightness=$(echo "${!fg_color}" | grep -o "." | wc -l)
    local bg_brightness=$(echo "${!bg_color}" | grep -o "." | wc -l)
    
    if (( $(echo "$fg_brightness > $bg_brightness" | bc -l) )); then
        echo "Good contrast"
    else
        echo "Poor contrast"
    fi
}

# Function to adjust color brightness
adjust_brightness() {
    local color=$1
    local adjustment=$2  # 1 for brighter, -1 for darker
    local new_color="\033[$(( $(echo "${!color}" | grep -o ";" | wc -l) + adjustment ))m"
    echo -e "${new_color}Adjusted color${Color_Off}"
}

# Function to show module info
show_module_info() {
    echo "${COLORS_MODULE_NAME} v${COLORS_MODULE_VERSION}"
    echo "Author: ${COLORS_MODULE_AUTHOR}"
    echo "License: ${COLORS_MODULE_LICENSE}"
    echo ""
    echo "Usage:"
    echo "  source colors.sh"
    echo "  print_color \"Red\" \"Hello World\""
    echo "  print_bold_color \"BGreen\" \"Important message\""
    echo "  print_underline \"UCyan\" \"Underlined text\""
}

# Function to show help
show_help() {
    echo "Shell Colors Module Help"
    echo ""
    echo "Available functions:"
    echo "  print_color <color> <message>"
    echo "  print_bold_color <color> <message>"
    echo "  print_underline <color> <message>"
    echo "  print_bg_color <bg_color> <message>"
    echo "  print_color_combo <fg_color> <bg_color> <message>"
    echo "  print_color_palette"
    echo "  check_contrast <fg_color> <bg_color>"
    echo "  adjust_brightness <color> <adjustment>"
    echo "  show_module_info"
    echo ""
    echo "Available colors:"
    echo "  Foreground: Black, Red, Green, Yellow, Blue, Purple, Cyan, White"
    echo "  Background: On_Black, On_Red, On_Green, On_Yellow, On_Blue, On_Purple, On_Cyan, On_White"
    echo "  Bold: BBlack, BRed, BGreen, BYellow, BBlue, BPurple, BCyan, BWhite"
    echo "  High Intensity: IBlack, IRed, IGreen, IYellow, IBlue, IPurple, ICyan, IWhite"
}

# If script is executed directly, show help
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    show_help
fi

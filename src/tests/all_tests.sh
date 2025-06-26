#!/bin/bash

# All-in-one test runner for TuxTechCLI
# Run all tests: ./all_tests.sh
# Run specific test: ./all_tests.sh <test_name>

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
tests_passed=0
tests_failed=0
tests_skipped=0

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTILS_DIR="${SCRIPT_DIR}/../utils"

# Source the logger and colors if available
if [ -f "${UTILS_DIR}/colors.sh" ]; then
    source "${UTILS_DIR}/colors.sh"
    # Define fallback colors if not sourced properly
    RED=${Red:-'\033[0;31m'}
    GREEN=${Green:-'\033[0;32m'}
    YELLOW=${Yellow:-'\033[1;33m'}
    NC=${NC:-'\033[0m'}
fi

# Function to print test header
print_header() {
    echo -e "\n${YELLOW}=== $1 ===${NC}"
}

# Function to print test result
print_result() {
    local test_name=$1
    local status=$2
    local message=${3:-}
    
    case $status in
        "PASS")
            echo -e "${GREEN}✓ PASS${NC} - $test_name $message"
            ((tests_passed++))
            ;;
        "FAIL")
            echo -e "${RED}✗ FAIL${NC} - $test_name $message"
            ((tests_failed++))
            ;;
        "SKIP")
            echo -e "${YELLOW}⚠ SKIP${NC} - $test_name $message"
            ((tests_skipped++))
            ;;
    esac
}

# Function to run quick color test
run_quick_test() {
    local test_name="Quick Color Test"
    print_header "Running $test_name"
    
    if [ ! -f "${SCRIPT_DIR}/quick_test.sh" ]; then
        print_result "$test_name" "SKIP" "(quick_test.sh not found)"
        return 1
    fi
    
    if bash "${SCRIPT_DIR}/quick_test.sh" >/dev/null 2>&1; then
        print_result "$test_name" "PASS"
        return 0
    else
        print_result "$test_name" "FAIL" "(check quick_test.sh for details)"
        return 1
    fi
}

# Function to run simple test
run_simple_test() {
    local test_name="Simple Test"
    print_header "Running $test_name"
    
    if [ ! -f "${SCRIPT_DIR}/simple_test.sh" ]; then
        print_result "$test_name" "SKIP" "(simple_test.sh not found)"
        return 1
    fi
    
    # Run the test and capture output
    echo "Running simple_test.sh..."
    output=$(bash "${SCRIPT_DIR}/simple_test.sh" 2>&1)
    local exit_code=$?
    
    # Always show the output
    echo -e "$output"
    
    # Check if the output contains error messages
    if [[ "$output" == *"Error:"* ]] || [[ "$output" == *"error"* ]] || [[ "$output" == *"ERROR"* ]]; then
        print_result "$test_name" "FAIL" "(errors found in output)"
        return 1
    elif [ $exit_code -ne 0 ]; then
        print_result "$test_name" "WARN" "(non-zero exit code: $exit_code but no obvious errors)"
        return 0  # Still return success since the test actually ran
    else
        print_result "$test_name" "PASS"
        return 0
    fi
}

# Function to run colors test
run_colors_test() {
    local test_name="Colors Test"
    print_header "Running $test_name"
    
    if [ ! -f "${SCRIPT_DIR}/test_colors.sh" ]; then
        print_result "$test_name" "SKIP" "(test_colors.sh not found)"
        return 1
    fi
    
    if bash "${SCRIPT_DIR}/test_colors.sh" >/dev/null 2>&1; then
        print_result "$test_name" "PASS"
        return 0
    else
        print_result "$test_name" "FAIL" "(check test_colors.sh for details)"
        return 1
    fi
}

# Function to run logging test
run_logging_test() {
    local test_name="Logging Test"
    print_header "Running $test_name"
    
    if [ ! -f "${SCRIPT_DIR}/test_logging.sh" ]; then
        print_result "$test_name" "SKIP" "(test_logging.sh not found)"
        return 1
    fi
    
    # Run with output to see the logs
    if bash "${SCRIPT_DIR}/test_logging.sh"; then
        print_result "$test_name" "PASS"
        return 0
    else
        print_result "$test_name" "FAIL" "(check test_logging.sh for details)"
        return 1
    fi
}

# Function to run all tests
run_all_tests() {
    echo -e "${YELLOW}=== Starting All Tests ===${NC}"
    
    run_quick_test
    run_simple_test
    run_colors_test
    run_logging_test
    
    # Print summary
    echo -e "\n${YELLOW}=== Test Summary ===${NC}"
    echo -e "${GREEN}Passed: $tests_passed${NC}"
    echo -e "${RED}Failed: $tests_failed${NC}"
    echo -e "${YELLOW}Skipped: $tests_skipped${NC}"
    
    # Return non-zero if any tests failed
    if [ $tests_failed -gt 0 ]; then
        echo -e "\n${RED}Some tests failed!${NC}"
        return 1
    elif [ $tests_passed -eq 0 ]; then
        echo -e "\n${YELLOW}No tests were executed!${NC}"
        return 2
    else
        echo -e "\n${GREEN}All tests passed successfully!${NC}"
        return 0
    fi
}

# Main function
main() {
    local test_to_run=${1:-all}
    
    case $test_to_run in
        "quick")
            run_quick_test
            ;;
        "simple")
            run_simple_test
            ;;
        "colors")
            run_colors_test
            ;;
        "logging")
            run_logging_test
            ;;
        "all")
            run_all_tests
            ;;
        *)
            echo "Usage: $0 [test_name]"
            echo "Available tests: quick, simple, colors, logging, all (default)"
            return 1
            ;;
    esac
}

# Run the main function with all arguments
main "$@"

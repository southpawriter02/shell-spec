#!/bin/bash
# Test runner for shell-spec

# --- Color Codes ---
COLOR_GREEN='\033[0;32m'
COLOR_RED='\033[0;31m'
COLOR_RESET='\033[0m'

# --- Source the assertion library ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/assertions.sh"

# --- Configuration ---
TEST_FILE_PATTERN=${1:-"*_test.sh"}
TEST_FUNCTION_PREFIX=${2:-"test_"}

# --- Counters ---
tests_run=0
tests_passed=0
tests_failed=0

# --- Test Discovery ---
echo "Discovering tests with pattern: $TEST_FILE_PATTERN"
test_files=$(find . -name "$TEST_FILE_PATTERN")

if [ -z "$test_files" ]; then
  echo "No test files found."
  exit 0
fi

# --- Test Execution ---
for file in $test_files; do
  echo ""
  echo "Running tests in: $file"

  # Source the test file to make its functions available in a subshell
  # This is to find the function names. The file will be sourced again
  # inside the subshell for each test function.
  source "$file"

  test_functions=$(declare -F | awk '{print $3}' | grep "^$TEST_FUNCTION_PREFIX")

  for func in $test_functions; do
    tests_run=$((tests_run + 1))

    # Run the test in a subshell for isolation
    (
      # Source the libraries again in the subshell
      source "$SCRIPT_DIR/assertions.sh"
      source "$file"
      $func
    )
    exit_code=$?

    if [ $exit_code -eq 0 ]; then
      tests_passed=$((tests_passed + 1))
      echo -e "  - ${COLOR_GREEN}PASS: $func${COLOR_RESET}"
    else
      tests_failed=$((tests_failed + 1))
      # The detailed fail message is already printed by the assertion from stderr
      echo -e "  - ${COLOR_RED}FAIL: $func${COLOR_RESET}"
    fi
  done
done

# --- Test Summary ---
echo ""
echo "--------------------"
echo "Test Summary"
echo "--------------------"
echo "Total tests: $tests_run"
echo -e "${COLOR_GREEN}Passed: $tests_passed${COLOR_RESET}"
echo -e "${COLOR_RED}Failed: $tests_failed${COLOR_RESET}"
echo "--------------------"

# --- Exit Code ---
if [ "$tests_failed" -eq 0 ]; then
  exit 0
else
  exit 1
fi

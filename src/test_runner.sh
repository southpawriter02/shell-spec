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
TEST_FILE_PATTERN="*_test.sh"
TEST_FUNCTION_PREFIX="test_"
HTML_REPORT_FILE=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --html)
      HTML_REPORT_FILE="$2"
      shift 2
      ;;
    *)
      # Assume it's the file pattern if not a flag
      TEST_FILE_PATTERN="$1"
      shift
      ;;
  esac
done

# --- Counters ---
tests_run=0
tests_passed=0
tests_failed=0

# --- JSON Result Collection ---
# We will store JSON objects in a temporary file to avoid complex string escaping issues with large output
json_results_file=$(mktemp)
echo "[]" > "$json_results_file"

# Helper to append a result to the JSON array
append_json_result() {
  local file="$1"
  local func="$2"
  local status="$3"
  local message="$4"

  # Remove ANSI color codes first
  # Use printf to avoid shell interpretation issues
  local cleaned_message=$(printf "%s" "$message" | sed 's/\x1b\[[0-9;]*m//g')

  # Escape backslashes and quotes
  local safe_message="${cleaned_message//\\/\\\\}"
  safe_message="${safe_message//\"/\\\"}"

  # Escape newlines for JSON
  safe_message="${safe_message//$'\n'/\\n}"

  # Construct JSON object
  local json_obj="{\"file\": \"$file\", \"test\": \"$func\", \"status\": \"$status\", \"message\": \"$safe_message\"}"

  # If it's the first element (file contains "[]"), just overwrite.
  # Otherwise append.
  # Actually, let's just write one object per line and wrap it later.
  echo "$json_obj" >> "$json_results_file"
}

# --- Test Discovery ---
echo "Discovering tests with pattern: $TEST_FILE_PATTERN"
test_files=$(find . -name "$TEST_FILE_PATTERN")

if [ -z "$test_files" ]; then
  echo "No test files found."
  exit 0
fi

# --- Test Execution ---
# clear the temp file for raw objects
> "$json_results_file"

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
    # Capture stderr to get failure messages
    output=$(
      (
        # Source the libraries again in the subshell
        source "$SCRIPT_DIR/assertions.sh"
        source "$file"
        $func
      ) 2>&1
    )
    exit_code=$?

    # Print output to console (reproduce original behavior)
    # If it failed, the output contains the error message.
    # If it passed, output is usually empty unless the test echoed something.

    if [ $exit_code -eq 0 ]; then
      tests_passed=$((tests_passed + 1))
      echo -e "  - ${COLOR_GREEN}PASS: $func${COLOR_RESET}"
      # If there was stdout output, we might want to show it, but original didn't explicitly handle mixed stdout/stderr well.
      # The original runner just let stdout/stderr flow to the terminal.
      # Since we captured it, we must print it now if we want to see it.
      if [ -n "$output" ]; then echo "$output"; fi

      append_json_result "$file" "$func" "PASS" ""
    else
      tests_failed=$((tests_failed + 1))
      echo -e "  - ${COLOR_RED}FAIL: $func${COLOR_RESET}"
      if [ -n "$output" ]; then echo "$output"; fi

      # Clean up output for JSON (take the last few lines which are likely the error message)
      append_json_result "$file" "$func" "FAIL" "$output"
    fi
  done
done

# --- Report Generation ---
if [ -n "$HTML_REPORT_FILE" ]; then
  echo "Generating HTML report: $HTML_REPORT_FILE"

  # Construct final JSON structure
  # Read all lines from temp file, comma separate them, wrap in []
  results_json=$(paste -sd, "$json_results_file")

  final_json="{
    \"summary\": {
      \"total\": $tests_run,
      \"passed\": $tests_passed,
      \"failed\": $tests_failed
    },
    \"results\": [$results_json]
  }"

  # Read template and replace placeholder
  template_path="$SCRIPT_DIR/report_template.html"
  if [ -f "$template_path" ]; then
    # Save final JSON to a temp file to avoid awk argument limits and escaping issues
    final_json_file=$(mktemp)
    echo "$final_json" > "$final_json_file"

    # Use awk to inject the JSON file content
    awk -v json_file="$final_json_file" '
      match($0, "{{TEST_DATA}}") {
        print substr($0, 1, RSTART-1)
        while ((getline line < json_file) > 0) {
          print line
        }
        close(json_file)
        print substr($0, RSTART+RLENGTH)
        next
      }
      { print }
    ' "$template_path" > "$HTML_REPORT_FILE"

    rm -f "$final_json_file"
    echo "Report saved to $HTML_REPORT_FILE"
  else
    echo "Error: Report template not found at $template_path"
  fi
fi

# Cleanup
rm -f "$json_results_file"

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

#!/bin/bash
# Test runner for shell-spec

# --- Configuration & Defaults ---
TEST_FILE_PATTERN="*_test.sh"
TEST_FUNCTION_PREFIX="test_"
HTML_REPORT_FILE=""
VERBOSE=false
WATCH_MODE=false
TAP_MODE=false

# --- Color Codes ---
if [ -z "${NO_COLOR:-}" ]; then
  COLOR_GREEN='\033[1;32m'
  COLOR_RED='\033[1;31m'
  COLOR_YELLOW='\033[1;33m'
  COLOR_BLUE='\033[1;34m'
  COLOR_BOLD='\033[1m'
  COLOR_RESET='\033[0m'
else
  COLOR_GREEN=''
  COLOR_RED=''
  COLOR_YELLOW=''
  COLOR_BLUE=''
  COLOR_BOLD=''
  COLOR_RESET=''
fi

# --- Source the assertion library, TAP reporter, and mocking library ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/assertions.sh"
source "$SCRIPT_DIR/tap_reporter.sh"
source "$SCRIPT_DIR/mocking.sh"

# --- Argument Parsing ---
while [[ $# -gt 0 ]]; do
  case $1 in
    --html)
      HTML_REPORT_FILE="$2"
      shift 2
      ;;
    --verbose)
      VERBOSE=true
      shift
      ;;
    --watch)
      WATCH_MODE=true
      shift
      ;;
    --tap)
      TAP_MODE=true
      shift
      ;;
    *)
      # Assume it's the file pattern if not a flag
      TEST_FILE_PATTERN="$1"
      shift
      ;;
  esac
done

# --- JSON Result Collection ---
json_results_file=$(mktemp)

# Ensure cleanup on exit
trap 'rm -f "$json_results_file"' EXIT

# Helper to append a result to the JSON array
append_json_result() {
  local file="$1"
  local func="$2"
  local status="$3"
  local message="$4"
  local duration="$5"

  # Remove ANSI color codes first
  local cleaned_message=$(printf "%s" "$message" | sed 's/\x1b\[[0-9;]*m//g')

  # Escape backslashes and quotes
  local safe_message="${cleaned_message//\\/\\\\}"
  safe_message="${safe_message//\"/\\\"}"
  safe_message="${safe_message//$'\n'/\\n}"

  local json_obj="{\"file\": \"$file\", \"test\": \"$func\", \"status\": \"$status\", \"message\": \"$safe_message\", \"duration_ms\": $duration}"
  echo "$json_obj" >> "$json_results_file"
}

# --- Directive Extraction ---
# Extract @SKIP or @TODO directive from comment preceding a function
# Args: $1 = file, $2 = function_name
# Output: "SKIP reason" or "TODO reason" or empty string
extract_directive() {
    local file="$1"
    local func="$2"

    # Find the line number of the function definition
    local func_line=$(grep -n "^${func}()" "$file" 2>/dev/null | head -1 | cut -d: -f1)

    if [[ -z "$func_line" || "$func_line" -le 1 ]]; then
        echo ""
        return
    fi

    # Get the line immediately before the function
    local prev_line=$((func_line - 1))
    local comment=$(sed -n "${prev_line}p" "$file")

    # Check for @SKIP directive
    if [[ "$comment" =~ ^[[:space:]]*#[[:space:]]*@SKIP[[:space:]]*(.*) ]]; then
        local reason="${BASH_REMATCH[1]}"
        echo "SKIP $reason"
        return
    fi

    # Check for @TODO directive
    if [[ "$comment" =~ ^[[:space:]]*#[[:space:]]*@TODO[[:space:]]*(.*) ]]; then
        local reason="${BASH_REMATCH[1]}"
        echo "TODO $reason"
        return
    fi

    echo ""
}

# --- Main Test Execution Function ---
run_all_tests() {
  # Initialize counters
  local tests_run=0
  local tests_passed=0
  local tests_failed=0
  local total_tests=0

  # Clear JSON results
  echo "" > "$json_results_file" # clear file but keep it existing. Wait, echo "" adds a newline.
  > "$json_results_file"

  # --- Test Discovery ---
  if $VERBOSE; then
    echo "Discovering tests with pattern: $TEST_FILE_PATTERN"
  fi

  local test_files=$(find . -name "$TEST_FILE_PATTERN")

  if [ -z "$test_files" ]; then
    echo "No test files found."
    return 0
  fi

  # --- Pre-pass: Count tests and build plan ---
  # array of "filename:function_name"
  local test_plan=()

  for file in $test_files; do
    # Run in subshell to avoid side effects
    local funcs=$(
      source "$file"
      declare -F | awk '{print $3}' | grep "^$TEST_FUNCTION_PREFIX"
    )
    for func in $funcs; do
      test_plan+=("$file:$func")
    done
  done

  total_tests=${#test_plan[@]}

  if [ "$total_tests" -eq 0 ]; then
     if $TAP_MODE; then
       tap_init
       tap_plan 0
     else
       echo "No tests found."
     fi
     return 0
  fi

  # Initialize output based on mode
  if $TAP_MODE; then
    tap_init
    tap_plan "$total_tests"
  elif ! $VERBOSE; then
    echo "Found $total_tests tests."
  fi

  # --- Execution Loop ---
  for item in "${test_plan[@]}"; do
    local file="${item%%:*}"
    local func="${item##*:}"

    tests_run=$((tests_run + 1))

    # Extract directive (SKIP/TODO) if present
    local directive=""
    if $TAP_MODE; then
      directive=$(extract_directive "$file" "$func")
    fi

    # Handle SKIP directive - don't run the test
    if [[ "$directive" == SKIP* ]]; then
      tests_passed=$((tests_passed + 1))
      if $TAP_MODE; then
        local skip_reason="${directive#SKIP }"
        tap_skip "$func" "$skip_reason"
      fi
      append_json_result "$file" "$func" "SKIP" "" "0"
      continue
    fi

    # Progress Bar (if not verbose and not TAP)
    if ! $TAP_MODE && ! $VERBOSE; then
      local percent=$(( tests_run * 100 / total_tests ))
      local progress=$(( percent / 5 )) # 20 chars bar
      local bar=""
      for ((i=0; i<progress; i++)); do bar+="="; done
      for ((i=progress; i<20; i++)); do bar+=" "; done
      printf "\rRunning tests: [%s] %d/%d (%d%%)" "$bar" "$tests_run" "$total_tests" "$percent"
    elif ! $TAP_MODE && $VERBOSE; then
      echo "Running $func in $file"
    fi

    # Run the test
    # Portable millisecond timestamp
    local start_time=$(python3 -c 'import time; print(int(time.time() * 1000))' 2>/dev/null || date +%s000)

    # Capture output
    output=$(
      (
        source "$SCRIPT_DIR/assertions.sh"
        source "$SCRIPT_DIR/mocking.sh"
        source "$file"
        $func
        _test_exit_code=$?
        unmock_all
        exit $_test_exit_code
      ) 2>&1
    )
    local exit_code=$?
    local end_time=$(python3 -c 'import time; print(int(time.time() * 1000))' 2>/dev/null || date +%s000)
    local duration=$((end_time - start_time))

    # Handle TODO directive specially
    if [[ "$directive" == TODO* ]]; then
      local todo_reason="${directive#TODO }"
      if [ $exit_code -eq 0 ]; then
        tests_passed=$((tests_passed + 1))
        if $TAP_MODE; then
          tap_todo "$func" "true" "$todo_reason"
        elif $VERBOSE; then
          echo -e "  - ${COLOR_GREEN}PASS: $func${COLOR_RESET} (${duration}ms) [TODO - unexpected pass!]"
          if [ -n "$output" ]; then echo "$output"; fi
        fi
        append_json_result "$file" "$func" "PASS" "" "$duration"
      else
        # TODO failures don't count as real failures
        tests_passed=$((tests_passed + 1))
        if $TAP_MODE; then
          tap_todo "$func" "false" "$todo_reason"
        elif $VERBOSE; then
          echo -e "  - ${COLOR_YELLOW}TODO: $func${COLOR_RESET} (${duration}ms) [expected failure]"
          if [ -n "$output" ]; then echo "$output"; fi
        fi
        append_json_result "$file" "$func" "TODO" "$output" "$duration"
      fi
      continue
    fi

    # Normal test result handling
    if [ $exit_code -eq 0 ]; then
      tests_passed=$((tests_passed + 1))
      if $TAP_MODE; then
        tap_ok "$func"
      elif $VERBOSE; then
        echo -e "  - ${COLOR_GREEN}PASS: $func${COLOR_RESET} (${duration}ms)"
        if [ -n "$output" ]; then echo "$output"; fi
      fi
      append_json_result "$file" "$func" "PASS" "" "$duration"
    else
      tests_failed=$((tests_failed + 1))
      if $TAP_MODE; then
        tap_not_ok "$func" "$output" "$file" "$func" "$duration"
      elif $VERBOSE; then
        echo -e "  - ${COLOR_RED}FAIL: $func${COLOR_RESET} (${duration}ms)"
        if [ -n "$output" ]; then echo "$output"; fi
      fi
      append_json_result "$file" "$func" "FAIL" "$output" "$duration"
    fi
  done

  # Suppress default output in TAP mode
  if ! $TAP_MODE; then
    if ! $VERBOSE; then
      echo "" # Newline after progress bar
    fi

    # --- Summary Table ---
    echo ""
    if [ "${NO_COLOR:-}" ]; then
        printf "| %-30s | %-30s | %-6s |\n" "File" "Test Function" "Status"
        printf "|%-32s|%-32s|%-8s|\n" "--------------------------------" "--------------------------------" "--------"
    else
        printf "| %-30s | %-30s | %-6s |\n" "File" "Test Function" "Status"
        printf "|%-32s|%-32s|%-8s|\n" "--------------------------------" "--------------------------------" "--------"
    fi

    # Read JSON results to build table
    while IFS= read -r line; do
        # Parse JSON line crudely to avoid dependencies
        local t_file=$(echo "$line" | sed -n 's/.*"file": "\([^"]*\)".*/\1/p')
        local t_func=$(echo "$line" | sed -n 's/.*"test": "\([^"]*\)".*/\1/p')
        local t_status=$(echo "$line" | sed -n 's/.*"status": "\([^"]*\)".*/\1/p')

        # Truncate if too long
        if [ ${#t_file} -gt 30 ]; then t_file="...${t_file: -27}"; fi
        if [ ${#t_func} -gt 30 ]; then t_func="${t_func:0:27}..."; fi

        if [ "$t_status" == "PASS" ] || [ "$t_status" == "SKIP" ] || [ "$t_status" == "TODO" ]; then
           if [ -z "${NO_COLOR:-}" ]; then
               printf "| %-30s | %-30s | ${COLOR_GREEN}%-6s${COLOR_RESET} |\n" "$t_file" "$t_func" "$t_status"
           else
               printf "| %-30s | %-30s | %-6s |\n" "$t_file" "$t_func" "$t_status"
           fi
        else
           if [ -z "${NO_COLOR:-}" ]; then
               printf "| %-30s | %-30s | ${COLOR_RED}%-6s${COLOR_RESET} |\n" "$t_file" "$t_func" "$t_status"
           else
               printf "| %-30s | %-30s | %-6s |\n" "$t_file" "$t_func" "$t_status"
           fi
        fi
    done < "$json_results_file"

    echo ""
    echo "--------------------"
    echo "Test Summary"
    echo "--------------------"
    echo "Total tests: $tests_run"
    echo -e "${COLOR_GREEN}Passed: $tests_passed${COLOR_RESET}"
    echo -e "${COLOR_RED}Failed: $tests_failed${COLOR_RESET}"
    echo "--------------------"
  fi  # End of !TAP_MODE block

  # --- Report Generation ---
  if [ -n "$HTML_REPORT_FILE" ]; then
    if ! $TAP_MODE; then
      echo "Generating HTML report: $HTML_REPORT_FILE"
    fi

    local results_json=$(paste -sd, "$json_results_file")
    local final_json="{
      \"summary\": {
        \"total\": $tests_run,
        \"passed\": $tests_passed,
        \"failed\": $tests_failed
      },
      \"results\": [$results_json]
    }"

    local template_path="$SCRIPT_DIR/report_template.html"
    if [ -f "$template_path" ]; then
      local final_json_file=$(mktemp)
      echo "$final_json" > "$final_json_file"

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
      if ! $TAP_MODE; then
        echo "Report saved to $HTML_REPORT_FILE"
      fi
    else
      if ! $TAP_MODE; then
        echo "Error: Report template not found at $template_path"
      fi
    fi
  fi

  if [ "$tests_failed" -gt 0 ]; then
      return 1
  else
      return 0
  fi
}

# --- Watch Mode Helper ---
calc_checksum() {
    # Find all sh files, stat them, sort to be consistent, and hash.
    # Use md5sum if available, else cksum
    if command -v md5sum >/dev/null 2>&1; then
        find . -name "*.sh" -type f -exec stat -c %Y {} + 2>/dev/null | md5sum | awk '{print $1}'
    else
        find . -name "*.sh" -type f -exec stat -f %m {} + 2>/dev/null | cksum | awk '{print $1}'
    fi
}

# --- Main Logic ---
if $WATCH_MODE; then
    echo -e "${COLOR_BLUE}${COLOR_BOLD}Starting Watch Mode...${COLOR_RESET}"

    last_checksum=""

    while true; do
        current_checksum=$(calc_checksum)

        if [ "$current_checksum" != "$last_checksum" ]; then
            # clear screen if possible
            if command -v clear >/dev/null; then clear; fi

            echo -e "${COLOR_BLUE}File change detected. Running tests...${COLOR_RESET}"
            run_all_tests
            # Capture exit code but don't exit

            last_checksum="$current_checksum"
            echo -e "\n${COLOR_YELLOW}Watching for changes...${COLOR_RESET}"
        fi

        sleep 2
    done
else
    run_all_tests
    exit $?
fi

# Cleanup is handled by trap

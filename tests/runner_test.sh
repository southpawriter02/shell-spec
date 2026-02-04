#!/bin/bash
# Self-tests for the shell-spec test runner
# These tests verify that the test runner correctly discovers, executes, and reports on tests.

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TEST_RUNNER="$PROJECT_ROOT/src/test_runner.sh"
FIXTURES_DIR="$SCRIPT_DIR/fixtures"

# --- Setup: Create fixture test files ---
setup_fixtures() {
  mkdir -p "$FIXTURES_DIR"
  
  # Fixture 1: A test file with all passing tests
  cat > "$FIXTURES_DIR/all_pass_test.sh" << 'EOF'
#!/bin/bash
test_one() { return 0; }
test_two() { return 0; }
test_three() { return 0; }
EOF

  # Fixture 2: A test file with some failing tests
  cat > "$FIXTURES_DIR/some_fail_test.sh" << 'EOF'
#!/bin/bash
test_pass() { return 0; }
test_fail() { return 1; }
EOF

  # Fixture 3: A test file with only failing tests
  cat > "$FIXTURES_DIR/all_fail_test.sh" << 'EOF'
#!/bin/bash
test_fail_one() { return 1; }
test_fail_two() { return 1; }
EOF

  # Fixture 4: A file without test_ functions (should be discovered but run 0 tests)
  cat > "$FIXTURES_DIR/no_tests_test.sh" << 'EOF'
#!/bin/bash
helper_function() { echo "I am not a test"; }
another_helper() { return 0; }
EOF

  # Fixture 5: A file that is not a test file (should not be discovered by *_test.sh pattern)
  cat > "$FIXTURES_DIR/helper_script.sh" << 'EOF'
#!/bin/bash
test_hidden() { echo "This should not run"; }
EOF
}

# --- Teardown: Remove fixture files ---
teardown_fixtures() {
  rm -rf "$FIXTURES_DIR"
}

# ============================================================================
# Tests for Test Discovery
# ============================================================================

test_runner_discovers_test_files() {
  setup_fixtures
  
  # Run from fixtures directory so find works correctly
  local output
  output=$(cd "$FIXTURES_DIR" && bash "$TEST_RUNNER" "*_test.sh" 2>&1)
  
  teardown_fixtures
  
  assert_output_contains "all_pass_test.sh" "echo '$output'"
}

test_runner_finds_multiple_test_files() {
  setup_fixtures
  
  local output
  output=$(cd "$FIXTURES_DIR" && bash "$TEST_RUNNER" "*_test.sh" 2>&1)
  
  teardown_fixtures
  
  # Should find multiple test files
  assert_output_contains "some_fail_test.sh" "echo '$output'"
  assert_output_contains "all_fail_test.sh" "echo '$output'"
}

test_runner_ignores_non_test_files() {
  setup_fixtures
  local output
  output=$(cd "$FIXTURES_DIR" && bash "$TEST_RUNNER" "*_test.sh" 2>&1)
  
  # The file helper_script.sh should NOT appear because it doesn't match *_test.sh
  local found_helper=0
  if [[ "$output" == *"helper_script.sh"* ]]; then
    found_helper=1
  fi
  
  teardown_fixtures
  assert_equals 0 "$found_helper" "Runner should not discover helper_script.sh"
}

test_runner_uses_custom_pattern() {
  setup_fixtures
  # Create a file with custom pattern
  cat > "$FIXTURES_DIR/my_spec.sh" << 'EOF'
#!/bin/bash
test_custom() { return 0; }
EOF
  
  local output
  output=$(cd "$FIXTURES_DIR" && bash "$TEST_RUNNER" "*_spec.sh" 2>&1)
  local found_spec=0
  [[ "$output" == *"my_spec.sh"* ]] && found_spec=1
  
  teardown_fixtures
  assert_equals 1 "$found_spec" "Runner should discover files matching custom pattern"
}

# ============================================================================
# Tests for Test Execution
# ============================================================================

test_runner_executes_test_functions() {
  setup_fixtures
  local output
  output=$(cd "$FIXTURES_DIR" && bash "$TEST_RUNNER" "all_pass_test.sh" 2>&1)
  teardown_fixtures
  
  assert_output_contains "test_one" "echo '$output'"
  assert_output_contains "test_two" "echo '$output'"
  assert_output_contains "test_three" "echo '$output'"
}

test_runner_skips_non_test_functions() {
  setup_fixtures
  local output
  output=$(cd "$FIXTURES_DIR" && bash "$TEST_RUNNER" "no_tests_test.sh" 2>&1)
  teardown_fixtures
  
  # helper_function should not appear as a test
  if [[ "$output" == *"helper_function"* ]]; then
    _report_fail "Runner should skip non-test functions" "function not executed" "function was executed"
  fi
}

# ============================================================================
# Tests for Exit Codes
# ============================================================================

test_runner_exits_zero_when_all_pass() {
  setup_fixtures
  (cd "$FIXTURES_DIR" && bash "$TEST_RUNNER" "all_pass_test.sh") >/dev/null 2>&1
  local exit_code=$?
  teardown_fixtures
  
  assert_equals 0 "$exit_code" "Runner should exit 0 when all tests pass"
}

test_runner_exits_nonzero_when_any_fail() {
  setup_fixtures
  (cd "$FIXTURES_DIR" && bash "$TEST_RUNNER" "some_fail_test.sh") >/dev/null 2>&1
  local exit_code=$?
  teardown_fixtures
  
  assert_equals 1 "$exit_code" "Runner should exit 1 when any test fails"
}

test_runner_exits_nonzero_when_all_fail() {
  setup_fixtures
  (cd "$FIXTURES_DIR" && bash "$TEST_RUNNER" "all_fail_test.sh") >/dev/null 2>&1
  local exit_code=$?
  teardown_fixtures
  
  assert_equals 1 "$exit_code" "Runner should exit 1 when all tests fail"
}

# ============================================================================
# Tests for Summary Output
# ============================================================================

test_runner_prints_summary() {
  setup_fixtures
  local output
  output=$(cd "$FIXTURES_DIR" && bash "$TEST_RUNNER" "all_pass_test.sh" 2>&1)
  teardown_fixtures
  
  assert_output_contains "Test Summary" "echo '$output'"
  assert_output_contains "Total tests" "echo '$output'"
  assert_output_contains "Passed" "echo '$output'"
}

test_runner_counts_tests_correctly() {
  setup_fixtures
  local output
  output=$(cd "$FIXTURES_DIR" && bash "$TEST_RUNNER" "all_pass_test.sh" 2>&1)
  teardown_fixtures
  
  assert_output_contains "Total tests: 3" "echo '$output'"
  assert_output_contains "Passed: 3" "echo '$output'"
  assert_output_contains "Failed: 0" "echo '$output'"
}

test_runner_counts_failures_correctly() {
  setup_fixtures
  local output
  output=$(cd "$FIXTURES_DIR" && bash "$TEST_RUNNER" "some_fail_test.sh" 2>&1)
  teardown_fixtures
  
  assert_output_contains "Total tests: 2" "echo '$output'"
  assert_output_contains "Passed: 1" "echo '$output'"
  assert_output_contains "Failed: 1" "echo '$output'"
}

# ============================================================================
# Tests for PASS/FAIL Output
# ============================================================================

test_runner_prints_pass_for_passing_tests() {
  setup_fixtures
  local output
  output=$(cd "$FIXTURES_DIR" && bash "$TEST_RUNNER" "all_pass_test.sh" 2>&1)
  teardown_fixtures
  
  assert_output_contains "PASS" "echo '$output'"
}

test_runner_prints_fail_for_failing_tests() {
  setup_fixtures
  local output
  output=$(cd "$FIXTURES_DIR" && bash "$TEST_RUNNER" "some_fail_test.sh" 2>&1)
  teardown_fixtures
  
  assert_output_contains "FAIL" "echo '$output'"
}

# ============================================================================
# Tests for HTML Report Generation
# ============================================================================

test_runner_generates_html_report() {
  setup_fixtures
  local report_file="$FIXTURES_DIR/test_report.html"
  
  (cd "$FIXTURES_DIR" && bash "$TEST_RUNNER" "all_pass_test.sh" --html "$report_file") >/dev/null 2>&1
  
  local file_exists=0
  [ -f "$report_file" ] && file_exists=1
  
  teardown_fixtures
  assert_equals 1 "$file_exists" "Runner should generate HTML report file"
}

test_html_report_contains_test_data() {
  setup_fixtures
  local report_file="$FIXTURES_DIR/test_report.html"
  
  (cd "$FIXTURES_DIR" && bash "$TEST_RUNNER" "all_pass_test.sh" --html "$report_file") >/dev/null 2>&1
  
  # Use grep to check for content, avoiding shell escaping issues
  local found_test=0
  [ -f "$report_file" ] && grep -q "test_one" "$report_file" && found_test=1
  
  teardown_fixtures
  assert_equals 1 "$found_test" "HTML report should contain test names"
}

test_html_report_contains_summary() {
  setup_fixtures
  local report_file="$FIXTURES_DIR/test_report.html"
  
  (cd "$FIXTURES_DIR" && bash "$TEST_RUNNER" "all_pass_test.sh" --html "$report_file") >/dev/null 2>&1
  
  # Use grep to check for summary data
  local found_total=0
  local found_passed=0
  if [ -f "$report_file" ]; then
    grep -q '"total"' "$report_file" && found_total=1
    grep -q '"passed"' "$report_file" && found_passed=1
  fi
  
  teardown_fixtures
  assert_equals 1 "$found_total" "HTML report should contain total count"
  assert_equals 1 "$found_passed" "HTML report should contain passed count"
}

# ============================================================================
# Tests for Test Isolation
# ============================================================================

test_runner_isolates_tests() {
  setup_fixtures
  
  # Create a test file where one test sets a variable and another checks it
  cat > "$FIXTURES_DIR/isolation_test.sh" << 'EOF'
#!/bin/bash
test_set_variable() {
  ISOLATION_TEST_VAR="I was set"
  return 0
}
test_check_variable_not_leaked() {
  # This should pass because ISOLATION_TEST_VAR should not leak from previous test
  if [ -z "$ISOLATION_TEST_VAR" ]; then
    return 0
  else
    return 1
  fi
}
EOF

  (cd "$FIXTURES_DIR" && bash "$TEST_RUNNER" "isolation_test.sh") >/dev/null 2>&1
  local exit_code=$?
  
  teardown_fixtures
  assert_equals 0 "$exit_code" "Tests should be isolated - variables should not leak"
}

# ============================================================================
# Tests for Edge Cases
# ============================================================================

test_runner_handles_no_test_files() {
  local temp_dir=$(mktemp -d)
  local output
  output=$(cd "$temp_dir" && bash "$TEST_RUNNER" "nonexistent_pattern_12345_test.sh" 2>&1)
  local exit_code=$?
  rm -rf "$temp_dir"
  
  assert_equals 0 "$exit_code" "Runner should exit 0 when no test files found"
  assert_output_contains "No test files found" "echo '$output'"
}

test_runner_handles_empty_test_file() {
  setup_fixtures
  
  # Create empty test file (no test functions)
  cat > "$FIXTURES_DIR/empty_test.sh" << 'EOF'
#!/bin/bash
# This file has no test functions
EOF

  local output
  output=$(cd "$FIXTURES_DIR" && bash "$TEST_RUNNER" "empty_test.sh" 2>&1)
  local exit_code=$?
  
  teardown_fixtures
  
  # Should complete without error
  assert_equals 0 "$exit_code" "Runner should handle empty test files gracefully"
}

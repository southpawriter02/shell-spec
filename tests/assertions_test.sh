#!/bin/bash
# Self-tests for the shell-spec assertion library
# This file tests the assertion functions themselves to ensure they work correctly.

# --- Helper Functions ---

# Captures the exit code of a function call
# Usage: capture_exit_code "function_call"
# Returns: Sets $CAPTURED_EXIT_CODE
capture_exit_code() {
  (eval "$1") >/dev/null 2>&1
  CAPTURED_EXIT_CODE=$?
}

# Captures stderr output from a function call
# Usage: capture_stderr "function_call"
# Returns: Sets $CAPTURED_STDERR
capture_stderr() {
  CAPTURED_STDERR=$( (eval "$1") 2>&1 >/dev/null )
}

# ============================================================================
# Tests for assert_equals
# ============================================================================

test_assert_equals_passes_when_values_match() {
  capture_exit_code 'assert_equals "hello" "hello"'
  assert_equals 0 "$CAPTURED_EXIT_CODE" "assert_equals should pass when values match"
}

test_assert_equals_fails_when_values_differ() {
  capture_exit_code 'assert_equals "hello" "world"'
  assert_equals 1 "$CAPTURED_EXIT_CODE" "assert_equals should fail when values differ"
}

test_assert_equals_handles_empty_strings() {
  capture_exit_code 'assert_equals "" ""'
  assert_equals 0 "$CAPTURED_EXIT_CODE" "assert_equals should pass for empty strings"
}

test_assert_equals_handles_numbers() {
  capture_exit_code 'assert_equals "42" "42"'
  assert_equals 0 "$CAPTURED_EXIT_CODE" "assert_equals should work with numbers"
}

test_assert_equals_handles_special_characters() {
  capture_exit_code 'assert_equals "hello world" "hello world"'
  assert_equals 0 "$CAPTURED_EXIT_CODE" "assert_equals should handle spaces"
}

# ============================================================================
# Tests for assert_not_equals
# ============================================================================

test_assert_not_equals_passes_when_values_differ() {
  capture_exit_code 'assert_not_equals "hello" "world"'
  assert_equals 0 "$CAPTURED_EXIT_CODE" "assert_not_equals should pass when values differ"
}

test_assert_not_equals_fails_when_values_match() {
  capture_exit_code 'assert_not_equals "hello" "hello"'
  assert_equals 1 "$CAPTURED_EXIT_CODE" "assert_not_equals should fail when values match"
}

test_assert_not_equals_handles_empty_vs_nonempty() {
  capture_exit_code 'assert_not_equals "" "something"'
  assert_equals 0 "$CAPTURED_EXIT_CODE" "assert_not_equals should pass for empty vs non-empty"
}

# ============================================================================
# Tests for assert_success
# ============================================================================

test_assert_success_passes_for_successful_command() {
  capture_exit_code 'assert_success "true"'
  assert_equals 0 "$CAPTURED_EXIT_CODE" "assert_success should pass for 'true' command"
}

test_assert_success_fails_for_failing_command() {
  capture_exit_code 'assert_success "false"'
  assert_equals 1 "$CAPTURED_EXIT_CODE" "assert_success should fail for 'false' command"
}

test_assert_success_passes_for_echo() {
  capture_exit_code 'assert_success "echo hello"'
  assert_equals 0 "$CAPTURED_EXIT_CODE" "assert_success should pass for echo command"
}

test_assert_success_fails_for_nonexistent_command() {
  capture_exit_code 'assert_success "command_that_does_not_exist_12345"'
  assert_equals 1 "$CAPTURED_EXIT_CODE" "assert_success should fail for non-existent command"
}

# ============================================================================
# Tests for assert_fail
# ============================================================================

test_assert_fail_passes_for_failing_command() {
  capture_exit_code 'assert_fail "false"'
  assert_equals 0 "$CAPTURED_EXIT_CODE" "assert_fail should pass for 'false' command"
}

test_assert_fail_fails_for_successful_command() {
  capture_exit_code 'assert_fail "true"'
  assert_equals 1 "$CAPTURED_EXIT_CODE" "assert_fail should fail for 'true' command"
}

test_assert_fail_passes_for_nonexistent_file() {
  capture_exit_code 'assert_fail "ls /nonexistent_path_12345"'
  assert_equals 0 "$CAPTURED_EXIT_CODE" "assert_fail should pass for ls on non-existent path"
}

# ============================================================================
# Tests for assert_output_equals
# ============================================================================

test_assert_output_equals_passes_when_output_matches() {
  capture_exit_code 'assert_output_equals "hello" "echo hello"'
  assert_equals 0 "$CAPTURED_EXIT_CODE" "assert_output_equals should pass when output matches"
}

test_assert_output_equals_fails_when_output_differs() {
  capture_exit_code 'assert_output_equals "hello" "echo world"'
  assert_equals 1 "$CAPTURED_EXIT_CODE" "assert_output_equals should fail when output differs"
}

test_assert_output_equals_handles_empty_output() {
  capture_exit_code 'assert_output_equals "" "true"'
  assert_equals 0 "$CAPTURED_EXIT_CODE" "assert_output_equals should handle empty output"
}

# ============================================================================
# Tests for assert_output_contains
# ============================================================================

test_assert_output_contains_passes_when_substring_found() {
  capture_exit_code 'assert_output_contains "world" "echo hello world"'
  assert_equals 0 "$CAPTURED_EXIT_CODE" "assert_output_contains should pass when substring found"
}

test_assert_output_contains_fails_when_substring_missing() {
  capture_exit_code 'assert_output_contains "foo" "echo hello world"'
  assert_equals 1 "$CAPTURED_EXIT_CODE" "assert_output_contains should fail when substring missing"
}

test_assert_output_contains_handles_full_match() {
  capture_exit_code 'assert_output_contains "hello" "echo hello"'
  assert_equals 0 "$CAPTURED_EXIT_CODE" "assert_output_contains should pass for full match"
}

# ============================================================================
# Tests for assert_file_exists
# ============================================================================

test_assert_file_exists_passes_for_existing_file() {
  local temp_file=$(mktemp)
  capture_exit_code "assert_file_exists \"$temp_file\""
  local result=$CAPTURED_EXIT_CODE
  rm -f "$temp_file"
  assert_equals 0 "$result" "assert_file_exists should pass for existing file"
}

test_assert_file_exists_fails_for_nonexistent_file() {
  capture_exit_code 'assert_file_exists "/nonexistent_file_12345.txt"'
  assert_equals 1 "$CAPTURED_EXIT_CODE" "assert_file_exists should fail for non-existent file"
}

test_assert_file_exists_passes_for_directory() {
  capture_exit_code 'assert_file_exists "/tmp"'
  assert_equals 0 "$CAPTURED_EXIT_CODE" "assert_file_exists should pass for directories"
}

# ============================================================================
# Tests for assert_file_not_exists
# ============================================================================

test_assert_file_not_exists_passes_for_nonexistent_file() {
  capture_exit_code 'assert_file_not_exists "/nonexistent_file_12345.txt"'
  assert_equals 0 "$CAPTURED_EXIT_CODE" "assert_file_not_exists should pass for non-existent file"
}

test_assert_file_not_exists_fails_for_existing_file() {
  local temp_file=$(mktemp)
  capture_exit_code "assert_file_not_exists \"$temp_file\""
  local result=$CAPTURED_EXIT_CODE
  rm -f "$temp_file"
  assert_equals 1 "$result" "assert_file_not_exists should fail for existing file"
}

# Note: assert_is_variable_set uses the [ -v ] operator which requires Bash 4.2+
# These tests check if the feature is available before running

test_assert_is_variable_set_passes_for_set_variable() {
  # Skip on Bash < 4.2 (no -v support)
  if [[ "${BASH_VERSINFO[0]}" -lt 4 || ("${BASH_VERSINFO[0]}" -eq 4 && "${BASH_VERSINFO[1]}" -lt 2) ]]; then
    return 0  # Skip test
  fi
  export MY_TEST_VAR="some_value"
  capture_exit_code 'assert_is_variable_set "MY_TEST_VAR"'
  unset MY_TEST_VAR
  assert_equals 0 "$CAPTURED_EXIT_CODE" "assert_is_variable_set should pass for set variable"
}

test_assert_is_variable_set_fails_for_unset_variable() {
  # Skip on Bash < 4.2 (no -v support)
  if [[ "${BASH_VERSINFO[0]}" -lt 4 || ("${BASH_VERSINFO[0]}" -eq 4 && "${BASH_VERSINFO[1]}" -lt 2) ]]; then
    return 0  # Skip test
  fi
  unset UNSET_TEST_VAR_12345
  capture_exit_code 'assert_is_variable_set "UNSET_TEST_VAR_12345"'
  assert_equals 1 "$CAPTURED_EXIT_CODE" "assert_is_variable_set should fail for unset variable"
}

test_assert_is_variable_set_passes_for_empty_string_variable() {
  # Skip on Bash < 4.2 (no -v support)
  if [[ "${BASH_VERSINFO[0]}" -lt 4 || ("${BASH_VERSINFO[0]}" -eq 4 && "${BASH_VERSINFO[1]}" -lt 2) ]]; then
    return 0  # Skip test
  fi
  export MY_EMPTY_VAR=""
  capture_exit_code 'assert_is_variable_set "MY_EMPTY_VAR"'
  unset MY_EMPTY_VAR
  assert_equals 0 "$CAPTURED_EXIT_CODE" "assert_is_variable_set should pass for empty string var"
}

# ============================================================================
# Tests for assert_is_function
# ============================================================================

my_test_function() {
  echo "I am a function"
}

test_assert_is_function_passes_for_defined_function() {
  capture_exit_code 'assert_is_function "my_test_function"'
  assert_equals 0 "$CAPTURED_EXIT_CODE" "assert_is_function should pass for defined function"
}

test_assert_is_function_fails_for_undefined_function() {
  capture_exit_code 'assert_is_function "nonexistent_function_12345"'
  assert_equals 1 "$CAPTURED_EXIT_CODE" "assert_is_function should fail for undefined function"
}

test_assert_is_function_fails_for_variable() {
  MY_VAR="not a function"
  capture_exit_code 'assert_is_function "MY_VAR"'
  unset MY_VAR
  assert_equals 1 "$CAPTURED_EXIT_CODE" "assert_is_function should fail for variables"
}

# ============================================================================
# Tests for failure message output
# ============================================================================

test_assert_equals_prints_failure_message() {
  capture_stderr 'assert_equals "expected" "actual"'
  assert_output_contains "expected" "echo '$CAPTURED_STDERR'"
  assert_output_contains "actual" "echo '$CAPTURED_STDERR'"
}

test_assert_equals_prints_fail_prefix() {
  capture_stderr 'assert_equals "a" "b"'
  assert_output_contains "FAIL" "echo '$CAPTURED_STDERR'"
}

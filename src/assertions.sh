#!/bin/sh

# sh-unit: The assertion library

# This file will contain the assertion functions for the sh-unit testing framework.
# Assertions should not exit the script. Instead, they should return a non-zero
# exit code if the assertion fails.

# --- Helper functions ---

# These variables will be used to track the number of passed and failed assertions.
# They are intended to be used by the test runner.
_SH_UNIT_ASSERTIONS_PASSED=0
_SH_UNIT_ASSERTIONS_FAILED=0

# A function to print a "PASS" message.
_print_pass() {
  _SH_UNIT_ASSERTIONS_PASSED=$((_SH_UNIT_ASSERTIONS_PASSED + 1))
  echo "      ✅ PASS: $1"
}

# A function to print a "FAIL" message.
# The second argument is optional and can be used to provide more context.
_print_fail() {
  _SH_UNIT_ASSERTIONS_FAILED=$((_SH_UNIT_ASSERTIONS_FAILED + 1))
  local message="$1"
  local details="$2"
  echo "      ❌ FAIL: $message"
  if [ -n "$details" ]; then
    echo "        $details"
  fi
  # Return a non-zero exit code to indicate failure.
  return 1
}

# --- Assertion functions ---

# Asserts that two values are equal.
# Usage: assert_equals <expected> <actual> [message]
assert_equals() {
  local expected="$1"
  local actual="$2"
  local message="${3:-Expected '$expected', got '$actual'}"

  if [ "$expected" = "$actual" ]; then
    _print_pass "should be equal"
  else
    _print_fail "$message"
  fi
}

# Asserts that a command executes with a success (zero) exit code.
# Usage: assert_success [command...]
assert_success() {
  "$@"
  local exit_code=$?
  local command_str="$*"

  if [ $exit_code -eq 0 ]; then
    _print_pass "command should succeed: $command_str"
  else
    _print_fail "command failed with exit code $exit_code: $command_str"
  fi
}

# Asserts that a command executes with a failure (non-zero) exit code.
# Usage: assert_fail [command...]
assert_fail() {
  "$@"
  local exit_code=$?
  local command_str="$*"

  if [ $exit_code -ne 0 ]; then
    _print_pass "command should fail: $command_str"
  else
    _print_fail "command succeeded, but was expected to fail: $command_str"
  fi
}

# Asserts that two values are not equal.
# Usage: assert_not_equals <unexpected> <actual> [message]
assert_not_equals() {
  local unexpected="$1"
  local actual="$2"
  local message="${3:-Expected values to be different, but both were '$actual'}"

  if [ "$unexpected" != "$actual" ]; then
    _print_pass "should not be equal"
  else
    _print_fail "$message"
  fi
}

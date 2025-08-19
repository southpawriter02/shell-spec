#!/bin/bash
# Assertion library for shell-spec

# --- Color Codes ---
COLOR_GREEN='\033[0;32m'
COLOR_RED='\033[0;31m'
COLOR_RESET='\033[0m'

# --- Helper Functions ---
# These helpers are called from within a test function running in a subshell.
_report_pass() {
  # The runner will report pass/fail, not the assertion itself.
  # This function can be used for verbose output if desired later.
  :
}

_report_fail() {
  # This message will be printed to stderr from the subshell.
  echo -e "${COLOR_RED}FAIL: $1${COLOR_RESET}" >&2
  echo "  - Expected: $2" >&2
  echo "  - Actual: $3" >&2
  exit 1
}

# --- Assertion Functions ---

assert_equals() {
  local expected="$1"
  local actual="$2"
  local message="${3:-"'$actual' should be equal to '$expected'"}"

  if [ "$expected" == "$actual" ]; then
    _report_pass "$message"
  else
    _report_fail "$message" "$expected" "$actual"
  fi
}

assert_not_equals() {
  local unexpected="$1"
  local actual="$2"
  local message="${3:-"'$actual' should not be equal to '$unexpected'"}"

  if [ "$unexpected" != "$actual" ]; then
    _report_pass "$message"
  else
    _report_fail "$message" "not equal to '$unexpected'" "'$actual'"
  fi
}

assert_success() {
  local command_to_run="$@"
  local message="command should succeed: $command_to_run"

  eval "$command_to_run" >/dev/null 2>&1
  local exit_code=$?

  if [ $exit_code -eq 0 ]; then
    _report_pass "$message"
  else
    _report_fail "$message" "exit code 0" "exit code $exit_code"
  fi
}

assert_fail() {
  local command_to_run="$@"
  local message="command should fail: $command_to_run"

  eval "$command_to_run" >/dev/null 2>&1
  local exit_code=$?

  if [ $exit_code -ne 0 ]; then
    _report_pass "$message"
  else
    _report_fail "$message" "non-zero exit code" "exit code $exit_code"
  fi
}

assert_output_equals() {
  local expected="$1"
  shift
  local command_to_run="$@"
  local message="output of '$command_to_run' should be '$expected'"

  local actual
  actual=$(eval "$command_to_run")

  if [ "$actual" == "$expected" ]; then
    _report_pass "$message"
  else
    _report_fail "$message" "$expected" "$actual"
  fi
}

assert_output_contains() {
  local substring="$1"
  shift
  local command_to_run="$@"
  local message="output of '$command_to_run' should contain '$substring'"

  local actual
  actual=$(eval "$command_to_run")

  if [[ "$actual" == *"$substring"* ]]; then
    _report_pass "$message"
  else
    _report_fail "$message" "output to contain '$substring'" "'$actual'"
  fi
}

assert_file_exists() {
  local path="$1"
  local message="file should exist: $path"

  if [ -e "$path" ]; then
    _report_pass "$message"
  else
    _report_fail "$message" "file exists" "file does not exist"
  fi
}

assert_file_not_exists() {
  local path="$1"
  local message="file should not exist: $path"

  if [ ! -e "$path" ]; then
    _report_pass "$message"
  else
    _report_fail "$message" "file does not exist" "file exists"
  fi
}

assert_is_variable_set() {
  local var_name="$1"
  local message="variable should be set: $var_name"

  if [ -v "$var_name" ]; then
    _report_pass "$message"
  else
    _report_fail "$message" "variable is set" "variable is not set"
  fi
}

assert_is_function() {
  local func_name="$1"
  local message="function should be defined: $func_name"

  if declare -f "$func_name" > /dev/null; then
    _report_pass "$message"
  else
    _report_fail "$message" "function is defined" "function is not defined"
  fi
}

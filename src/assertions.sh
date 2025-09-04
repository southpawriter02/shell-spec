#!/bin/bash
#
# assertions.sh: A library of assertion functions for sh-unit.

# --- Utility functions ---

_assert_result() {
    local status=$1
    local message=$2
    local details=$3

    if [ "$status" = "PASS" ]; then
        echo "    PASS: $message"
        return 0
    else
        echo "    FAIL: $message"
        if [ -n "$details" ]; then
            echo "      $details"
        fi
        return 1
    fi
}

# --- Assertion functions ---

assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="Expected '$expected', got '$actual'"

    if [ "$expected" = "$actual" ]; then
        _assert_result "PASS" "Values are equal."
    else
        _assert_result "FAIL" "Values are not equal." "$message"
    fi
}

assert_not_equals() {
    local expected="$1"
    local actual="$2"
    local message="Expected values to be different, but both are '$expected'"

    if [ "$expected" != "$actual" ]; then
        _assert_result "PASS" "Values are not equal."
    else
        _assert_result "FAIL" "Values are equal." "$message"
    fi
}

assert_success() {
    local command_to_run="$@"
    $command_to_run > /dev/null 2>&1
    local exit_code=$?
    local message="Expected command to succeed, but it failed with exit code $exit_code"

    if [ $exit_code -eq 0 ]; then
        _assert_result "PASS" "Command succeeded."
    else
        _assert_result "FAIL" "Command failed." "$message"
    fi
}

assert_fail() {
    local command_to_run="$@"
    $command_to_run > /dev/null 2>&1
    local exit_code=$?
    local message="Expected command to fail, but it succeeded."

    if [ $exit_code -ne 0 ]; then
        _assert_result "PASS" "Command failed as expected."
    else
        _assert_result "FAIL" "Command succeeded." "$message"
    fi
}

assert_output_equals() {
    local expected_output="$1"
    shift
    local command_to_run="$@"
    local actual_output=$($command_to_run)
    local message="Expected output '$expected_output', got '$actual_output'"

    if [ "$actual_output" = "$expected_output" ]; then
        _assert_result "PASS" "Command output is as expected."
    else
        _assert_result "FAIL" "Command output is not as expected." "$message"
    fi
}

assert_output_contains() {
    local expected_substring="$1"
    shift
    local command_to_run="$@"
    local actual_output=$($command_to_run)
    local message="Expected output to contain '$expected_substring', but it did not."

    if [[ "$actual_output" == *"$expected_substring"* ]]; then
        _assert_result "PASS" "Command output contains the expected substring."
    else
        _assert_result "FAIL" "Command output does not contain the expected substring." "$message"
    fi
}

assert_file_exists() {
    local file_path="$1"
    local message="Expected file '$file_path' to exist, but it does not."

    if [ -e "$file_path" ]; then
        _assert_result "PASS" "File exists."
    else
        _assert_result "FAIL" "File does not exist." "$message"
    fi
}

assert_file_not_exists() {
    local file_path="$1"
    local message="Expected file '$file_path' to not exist, but it does."

    if [ ! -e "$file_path" ]; then
        _assert_result "PASS" "File does not exist."
    else
        _assert_result "FAIL" "File exists." "$message"
    fi
}

assert_is_variable_set() {
    local var_name="$1"
    # Using indirect expansion
    if [ -n "${!var_name}" ]; then
        _assert_result "PASS" "Variable '$var_name' is set."
    else
        _assert_result "FAIL" "Variable '$var_name' is not set."
    fi
}

assert_is_function() {
    local func_name="$1"
    if declare -F "$func_name" > /dev/null; then
        _assert_result "PASS" "Function '$func_name' is defined."
    else
        _assert_result "FAIL" "Function '$func_name' is not defined."
    fi
}

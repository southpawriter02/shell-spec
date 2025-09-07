#!/bin/bash

# This is an example test file for the shell-spec framework.

# A simple function to be tested.
my_function() {
  echo "hello world"
}

# --- Test Functions ---

test_assert_equals_pass() {
  assert_equals "hello" "hello" "Two hellos should be equal"
}

test_assert_equals_fail() {
  assert_equals "hello" "world" "Hello and world should not be equal"
}

test_assert_not_equals_pass() {
  assert_not_equals "hello" "world" "Hello and world should not be equal"
}

test_command_success() {
  assert_success "echo 'hello'"
}

test_command_failure() {
  assert_fail "ls non_existent_file"
}

test_output_contains() {
  assert_output_contains "world" "my_function"
}

test_file_exists() {
  touch temp_file.txt
  assert_file_exists "temp_file.txt"
  rm temp_file.txt
}

test_variable_is_set() {
    local my_var="some_value"
    assert_is_variable_set "my_var"
}

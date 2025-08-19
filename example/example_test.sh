#!/bin/sh

# An example test file for sh-unit.

# A test that uses assertions.
test_addition() {
  local result=$(( 1 + 1 ))
  assert_equals 2 "$result" "one plus one should be two"
}

# Another test that uses assertions.
test_string_manipulation() {
  local greeting="hello"
  assert_equals "hello" "$greeting"
  assert_not_equals "world" "$greeting"
}

# A test that checks the success of a command.
test_command_success() {
  assert_success true # 'true' always exits with 0
}

# A test that checks the failure of a command.
test_command_failure() {
  assert_fail false # 'false' always exits with 1
}

# This is not a test function and should not be run.
do_something_else() {
  echo "This should not be printed during a test run."
}

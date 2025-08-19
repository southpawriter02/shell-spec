#!/bin/sh

# An example test file for sh-unit.

# A test that should always pass.
test_addition() {
  local result=$(( 1 + 1 ))
  return $(( result == 2 ? 0 : 1 ))
}

# A test that should always fail.
test_failing_test() {
  return 1
}

# This is not a test function and should not be run.
do_something_else() {
  echo "This should not be printed during a test run."
}

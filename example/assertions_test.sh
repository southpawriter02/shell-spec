#!/bin/bash
#
# Example test for the assertion library.

# A function to be tested
my_function() {
    echo "hello"
}

# Test cases
test_assert_equals() {
    assert_equals "hello" "hello"
    assert_equals "world" "world"
}

test_assert_not_equals() {
    assert_not_equals "hello" "world"
}

test_assert_success() {
    assert_success ls /
}

test_assert_fail() {
    assert_fail ls /non_existent_dir
}

test_assert_output_equals() {
    assert_output_equals "hello" my_function
}

test_assert_output_contains() {
    assert_output_contains "ell" my_function
}

test_assert_file_exists() {
    touch /tmp/test_file
    assert_file_exists /tmp/test_file
    rm /tmp/test_file
}

test_assert_file_not_exists() {
    assert_file_not_exists /tmp/non_existent_file
}

test_assert_is_variable_set() {
    local my_var="some_value"
    assert_is_variable_set my_var
}

test_assert_is_function() {
    assert_is_function my_function
}

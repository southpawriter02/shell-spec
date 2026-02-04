#!/bin/bash
# =============================================================================
# mocking_test.sh - Unit tests for mocking library
# =============================================================================

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# Source the mocking library and assertions
source "$SCRIPT_DIR/../src/mocking.sh"
source "$SCRIPT_DIR/../src/assertions.sh"

# --- Test: mock_command creates callable function ---
test_mock_command_creates_function() {
    unmock_all
    mock_command "mytest_cmd" 'echo "mocked"'

    # Verify function exists
    if ! declare -f mytest_cmd > /dev/null 2>&1; then
        assert_fail "echo 'mock_command should create a function'"
    fi

    # Verify function works
    local output=$(mytest_cmd)
    assert_equals "mocked" "$output"

    unmock_all
}

# --- Test: mock_command receives arguments ---
test_mock_command_receives_arguments() {
    unmock_all
    mock_command "mytest_cmd" 'echo "args: $@"'

    local output=$(mytest_cmd arg1 arg2 arg3)
    assert_equals "args: arg1 arg2 arg3" "$output"

    unmock_all
}

# --- Test: mock_command can return exit codes ---
test_mock_command_exit_code() {
    unmock_all
    mock_command "mytest_cmd" 'return 42'

    mytest_cmd
    local exit_code=$?
    assert_equals "42" "$exit_code"

    unmock_all
}

# --- Test: mock_command rejects shell builtins ---
test_mock_command_rejects_builtin() {
    unmock_all

    # Attempt to mock 'cd' should fail
    local output
    output=$(mock_command "cd" 'echo "bad"' 2>&1)
    local exit_code=$?

    assert_equals "1" "$exit_code"
    assert_output_contains "cannot mock shell builtin" "echo '$output'"

    unmock_all
}

# --- Test: mock_command rejects double mocking ---
test_mock_command_rejects_double_mock() {
    unmock_all
    mock_command "mytest_cmd" 'echo "first"'

    local output
    output=$(mock_command "mytest_cmd" 'echo "second"' 2>&1)
    local exit_code=$?

    assert_equals "1" "$exit_code"
    assert_output_contains "already mocked" "echo '$output'"

    unmock_all
}

# --- Test: mock_command requires command name ---
test_mock_command_requires_name() {
    unmock_all

    local output
    output=$(mock_command "" 'echo "test"' 2>&1)
    local exit_code=$?

    assert_equals "1" "$exit_code"
    assert_output_contains "command name required" "echo '$output'"
}

# --- Test: mock_command requires implementation ---
test_mock_command_requires_impl() {
    unmock_all

    local output
    output=$(mock_command "mytest_cmd" "" 2>&1)
    local exit_code=$?

    assert_equals "1" "$exit_code"
    assert_output_contains "implementation required" "echo '$output'"
}

# --- Test: stub_function replaces existing function ---
test_stub_function_replaces_function() {
    unmock_all

    # Create original function
    original_func() { echo "original"; }

    # Stub it
    stub_function "original_func" 'echo "stubbed"'

    local output=$(original_func)
    assert_equals "stubbed" "$output"

    unmock_all
}

# --- Test: stub_function saves original ---
test_stub_function_saves_original() {
    unmock_all

    # Create original function
    my_helper() { echo "original helper"; }

    # Stub it
    stub_function "my_helper" 'echo "stubbed helper"'

    # Verify original was saved (check by restoring)
    local idx=$(_get_orig_func_index "my_helper")
    if [[ -z "$idx" ]]; then
        assert_fail "echo 'Original function should be saved'"
    fi

    unmock_all
}

# --- Test: unstub_function restores original ---
test_unstub_function_restores_original() {
    unmock_all

    # Create original function
    restore_test() { echo "original"; }

    # Stub it
    stub_function "restore_test" 'echo "stubbed"'

    # Verify stub is active
    local stubbed_output=$(restore_test)
    assert_equals "stubbed" "$stubbed_output"

    # Unstub
    unstub_function "restore_test"

    # Verify original is restored
    local restored_output=$(restore_test)
    assert_equals "original" "$restored_output"

    unmock_all
}

# --- Test: stub_function rejects double stubbing ---
test_stub_function_rejects_double_stub() {
    unmock_all

    stub_function "double_stub_test" 'echo "first"'

    local output
    output=$(stub_function "double_stub_test" 'echo "second"' 2>&1)
    local exit_code=$?

    assert_equals "1" "$exit_code"
    assert_output_contains "already stubbed" "echo '$output'"

    unmock_all
}

# --- Test: unmock_command removes mock ---
test_unmock_command_removes_mock() {
    unmock_all
    mock_command "removable_cmd" 'echo "mocked"'

    # Verify mock exists
    assert_success "declare -f removable_cmd > /dev/null"

    # Remove mock
    unmock_command "removable_cmd"

    # Verify mock is gone
    if declare -f removable_cmd > /dev/null 2>&1; then
        assert_fail "echo 'Mock should be removed'"
    fi
}

# --- Test: unmock_command fails for non-mocked ---
test_unmock_command_fails_for_nonmocked() {
    unmock_all

    local output
    output=$(unmock_command "never_mocked_cmd" 2>&1)
    local exit_code=$?

    assert_equals "1" "$exit_code"
    assert_output_contains "not mocked" "echo '$output'"
}

# --- Test: unmock_all clears everything ---
test_unmock_all_clears_everything() {
    # Create some mocks and stubs
    mock_command "clear_test_cmd1" 'echo "one"'
    mock_command "clear_test_cmd2" 'echo "two"'
    stub_function "clear_test_func" 'echo "stubbed"'

    # Verify they exist
    assert_success "declare -f clear_test_cmd1 > /dev/null"
    assert_success "declare -f clear_test_cmd2 > /dev/null"

    # Clear all
    unmock_all

    # Verify arrays are empty
    assert_equals "0" "${#_SHELL_SPEC_MOCKED_COMMANDS[@]}"
    assert_equals "0" "${#_SHELL_SPEC_STUBBED_FUNCTIONS[@]}"

    # Verify functions are gone
    if declare -f clear_test_cmd1 > /dev/null 2>&1; then
        assert_fail "echo 'Mock should be cleared'"
    fi
}

# --- Test: is_mocked returns correct value ---
test_is_mocked_returns_correct() {
    unmock_all
    mock_command "check_mock_cmd" 'echo "test"'

    if ! is_mocked "check_mock_cmd"; then
        assert_fail "echo 'is_mocked should return true for mocked command'"
    fi

    if is_mocked "nonexistent_cmd"; then
        assert_fail "echo 'is_mocked should return false for non-mocked command'"
    fi

    unmock_all
}

# --- Test: is_stubbed returns correct value ---
test_is_stubbed_returns_correct() {
    unmock_all
    stub_function "check_stub_func" 'echo "test"'

    if ! is_stubbed "check_stub_func"; then
        assert_fail "echo 'is_stubbed should return true for stubbed function'"
    fi

    if is_stubbed "nonexistent_func"; then
        assert_fail "echo 'is_stubbed should return false for non-stubbed function'"
    fi

    unmock_all
}

# --- Test: list_mocks output ---
test_list_mocks_output() {
    unmock_all
    mock_command "list_test_cmd" 'echo "test"'
    stub_function "list_test_func" 'echo "test"'

    local output=$(list_mocks)

    assert_output_contains "list_test_cmd" "echo '$output'"
    assert_output_contains "list_test_func" "echo '$output'"

    unmock_all
}

# --- Test: list_mocks shows none when empty ---
test_list_mocks_empty() {
    unmock_all

    local output=$(list_mocks)

    assert_output_contains "none" "echo '$output'"
}

# --- Test: stub can create new function ---
test_stub_creates_new_function() {
    unmock_all

    # Stub a function that doesn't exist yet
    stub_function "brand_new_func" 'echo "created"'

    local output=$(brand_new_func)
    assert_equals "created" "$output"

    # Unstub should just remove it (no original to restore)
    unstub_function "brand_new_func"

    if declare -f brand_new_func > /dev/null 2>&1; then
        assert_fail "echo 'Function should be removed after unstub'"
    fi
}

# --- Test: mock with complex implementation ---
test_mock_complex_implementation() {
    unmock_all

    # Implementation that counts args - simplified to work with eval
    mock_command "complex_cmd" 'echo "count: $#"; return $#'

    local output
    output=$(complex_cmd a b c d e)
    local exit_code=$?

    assert_equals "count: 5" "$output"
    assert_equals "5" "$exit_code"

    unmock_all
}


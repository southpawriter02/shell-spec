#!/bin/bash
# =============================================================================
# mock_integration_test.sh - Integration tests for mocking in test runner
# =============================================================================

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
RUNNER="$SCRIPT_DIR/../../src/test_runner.sh"

# Source assertions
source "$SCRIPT_DIR/../../src/assertions.sh"

# --- Helper to create temp test files ---
TEMP_DIR="$SCRIPT_DIR/tmp"
mkdir -p "$TEMP_DIR"

create_temp_test() {
    local content="$1"
    local test_file="$TEMP_DIR/mock_temp_$$_${RANDOM}_test.sh"
    echo "$content" > "$test_file"
    echo "$test_file"
}

cleanup_temp_test() {
    rm -f "$1"
}

# --- Test: Mock in real test scenario ---
test_mock_in_real_test_scenario() {
    local test_file=$(create_temp_test '
source "'$SCRIPT_DIR'/../../src/mocking.sh"
source "'$SCRIPT_DIR'/../../src/assertions.sh"

test_curl_mock() {
    mock_command "curl" '\''echo "{\"status\": \"ok\"}"'\''
    local result=$(curl https://api.example.com/status)
    assert_equals "{\"status\": \"ok\"}" "$result"
}
')
    local pattern=$(basename "$test_file")

    local output=$(bash "$RUNNER" "$pattern" 2>&1)
    local exit_code=$?
    cleanup_temp_test "$test_file"

    assert_equals "0" "$exit_code"
    if echo "$output" | grep -q "FAIL"; then
        assert_fail "echo 'Test with mock should pass'"
    fi
}

# --- Test: Multiple mocks in single test ---
test_multiple_mocks_in_single_test() {
    local test_file=$(create_temp_test '
source "'$SCRIPT_DIR'/../../src/mocking.sh"
source "'$SCRIPT_DIR'/../../src/assertions.sh"

test_multiple_mocks() {
    mock_command "git" '\''echo "mocked git: $@"'\''
    mock_command "npm" '\''echo "mocked npm: $@"'\''
    mock_command "curl" '\''echo "mocked curl"'\''

    local git_out=$(git status)
    local npm_out=$(npm install)
    local curl_out=$(curl http://example.com)

    assert_output_contains "mocked git" "echo '\''$git_out'\''"
    assert_output_contains "mocked npm" "echo '\''$npm_out'\''"
    assert_equals "mocked curl" "$curl_out"
}
')
    local pattern=$(basename "$test_file")

    local output=$(bash "$RUNNER" "$pattern" 2>&1)
    local exit_code=$?
    cleanup_temp_test "$test_file"

    assert_equals "0" "$exit_code"
}

# --- Test: Mock isolation between tests (test 1 creates mock) ---
test_mock_isolation_test_1() {
    local test_file=$(create_temp_test '
source "'$SCRIPT_DIR'/../../src/mocking.sh"
source "'$SCRIPT_DIR'/../../src/assertions.sh"

test_create_mock() {
    mock_command "isolation_test_cmd" '\''echo "from test 1"'\''
    local out=$(isolation_test_cmd)
    assert_equals "from test 1" "$out"
}

test_verify_no_leak() {
    # This should NOT see the mock from test_create_mock
    # because each test runs in its own subshell
    if declare -f isolation_test_cmd > /dev/null 2>&1; then
        # Mock leaked - this is bad
        assert_fail "echo '\''Mock should not leak between tests'\''"
    fi
}
')
    local pattern=$(basename "$test_file")

    local output=$(bash "$RUNNER" "$pattern" 2>&1)
    local exit_code=$?
    cleanup_temp_test "$test_file"

    assert_equals "0" "$exit_code"
}

# --- Test: Stub with original restoration ---
test_stub_with_original_restoration() {
    local test_file=$(create_temp_test '
source "'$SCRIPT_DIR'/../../src/mocking.sh"
source "'$SCRIPT_DIR'/../../src/assertions.sh"

my_helper() {
    echo "original helper output"
}

test_stub_lifecycle() {
    # Verify original
    local before=$(my_helper)
    assert_equals "original helper output" "$before"

    # Stub it
    stub_function "my_helper" '\''echo "stubbed output"'\''
    local during=$(my_helper)
    assert_equals "stubbed output" "$during"

    # Restore
    unstub_function "my_helper"
    local after=$(my_helper)
    assert_equals "original helper output" "$after"
}
')
    local pattern=$(basename "$test_file")

    local output=$(bash "$RUNNER" "$pattern" 2>&1)
    local exit_code=$?
    cleanup_temp_test "$test_file"

    assert_equals "0" "$exit_code"
}

# --- Test: Mock works with TAP output ---
test_mock_with_tap_output() {
    local test_file=$(create_temp_test '
source "'$SCRIPT_DIR'/../../src/mocking.sh"
source "'$SCRIPT_DIR'/../../src/assertions.sh"

test_mock_tap() {
    mock_command "wget" '\''echo "mocked wget"'\''
    local out=$(wget http://example.com)
    assert_equals "mocked wget" "$out"
}
')
    local pattern=$(basename "$test_file")

    local output=$(bash "$RUNNER" --tap "$pattern" 2>&1)
    local exit_code=$?
    cleanup_temp_test "$test_file"

    # Should have TAP output
    if ! echo "$output" | grep -q "TAP version 13"; then
        assert_fail "echo 'Should have TAP header'"
    fi

    # Should have ok result
    if ! echo "$output" | grep -q "^ok 1 - test_mock_tap$"; then
        assert_fail "echo 'Test should pass in TAP mode'"
    fi

    assert_equals "0" "$exit_code"
}

# --- Test: Mock works with verbose mode ---
test_mock_with_verbose() {
    local test_file=$(create_temp_test '
source "'$SCRIPT_DIR'/../../src/mocking.sh"
source "'$SCRIPT_DIR'/../../src/assertions.sh"

test_mock_verbose() {
    mock_command "rsync" '\''echo "mocked rsync: $@"'\''
    local out=$(rsync -av /src /dst)
    assert_output_contains "mocked rsync" "echo '\''$out'\''"
}
')
    local pattern=$(basename "$test_file")

    local output=$(bash "$RUNNER" --verbose "$pattern" 2>&1)
    local exit_code=$?
    cleanup_temp_test "$test_file"

    # Should show verbose output
    if ! echo "$output" | grep -q "Running test_mock_verbose"; then
        assert_fail "echo 'Should have verbose output'"
    fi

    # Should pass
    if ! echo "$output" | grep -q "PASS"; then
        assert_fail "echo 'Test should pass in verbose mode'"
    fi

    assert_equals "0" "$exit_code"
}

# --- Test: Mock failure shows in output ---
test_mock_failure_reported() {
    local test_file=$(create_temp_test '
source "'$SCRIPT_DIR'/../../src/mocking.sh"
source "'$SCRIPT_DIR'/../../src/assertions.sh"

test_mock_returns_error() {
    mock_command "failing_cmd" '\''return 1'\''
    failing_cmd
    # This test intentionally fails because failing_cmd returns 1
}
')
    local pattern=$(basename "$test_file")

    local output
    output=$(bash "$RUNNER" "$pattern" 2>&1)
    local exit_code=$?
    cleanup_temp_test "$test_file"

    # Test should fail
    assert_equals "1" "$exit_code"

    # Should show failure in output
    if ! echo "$output" | grep -q "FAIL"; then
        assert_fail "echo 'Failure should be shown in output'"
    fi
}


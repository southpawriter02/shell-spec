#!/bin/bash
# =============================================================================
# tap_mode_test.sh - Integration tests for TAP mode in test runner
# =============================================================================

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
RUNNER="$SCRIPT_DIR/../../src/test_runner.sh"

# Source assertions
source "$SCRIPT_DIR/../../src/assertions.sh"

# --- Helper to create temp test files ---
# Creates temp files in tests/integration/tmp/ so find can locate them
TEMP_DIR="$SCRIPT_DIR/tmp"
mkdir -p "$TEMP_DIR"

create_temp_test() {
    local content="$1"
    local test_file="$TEMP_DIR/temp_$$_${RANDOM}_test.sh"
    echo "$content" > "$test_file"
    echo "$test_file"
}

cleanup_temp_test() {
    rm -f "$1"
}

# --- Test: TAP mode produces version header ---
test_tap_mode_version_header() {
    local test_file=$(create_temp_test 'test_pass() { true; }')
    local pattern=$(basename "$test_file")

    local output=$(bash "$RUNNER" --tap "$pattern" 2>&1)
    cleanup_temp_test "$test_file"

    if ! echo "$output" | head -1 | grep -q "TAP version 13"; then
        assert_fail "echo 'First line should be TAP version 13'"
    fi
}

# --- Test: TAP mode produces correct plan ---
test_tap_mode_plan_count() {
    local test_file=$(create_temp_test '
test_one() { true; }
test_two() { true; }
test_three() { true; }
')
    local pattern=$(basename "$test_file")

    local output=$(bash "$RUNNER" --tap "$pattern" 2>&1)
    cleanup_temp_test "$test_file"

    if ! echo "$output" | grep -q "1..3"; then
        assert_fail "echo 'Plan should be 1..3'"
    fi
}

# --- Test: TAP mode ok output for passing test ---
test_tap_mode_ok_output() {
    local test_file=$(create_temp_test 'test_pass() { true; }')
    local pattern=$(basename "$test_file")

    local output=$(bash "$RUNNER" --tap "$pattern" 2>&1)
    cleanup_temp_test "$test_file"

    if ! echo "$output" | grep -q "^ok 1 - test_pass$"; then
        assert_fail "echo 'Should have ok output for passing test'"
    fi
}

# --- Test: TAP mode not ok output for failing test ---
test_tap_mode_not_ok_output() {
    local test_file=$(create_temp_test 'test_fail() { false; }')
    local pattern=$(basename "$test_file")

    local output=$(bash "$RUNNER" --tap "$pattern" 2>&1)
    cleanup_temp_test "$test_file"

    if ! echo "$output" | grep -q "^not ok 1 - test_fail$"; then
        assert_fail "echo 'Should have not ok output for failing test'"
    fi
}

# --- Test: TAP mode YAML block for failures ---
test_tap_mode_yaml_block() {
    local test_file=$(create_temp_test '
source "'"$SCRIPT_DIR"'/../../src/assertions.sh"
test_fail() { assert_equals "foo" "bar"; }
')
    local pattern=$(basename "$test_file")

    local output=$(bash "$RUNNER" --tap "$pattern" 2>&1)
    cleanup_temp_test "$test_file"

    if ! echo "$output" | grep -q "  ---"; then
        assert_fail "echo 'Should have YAML block start'"
    fi
    if ! echo "$output" | grep -q "  severity: fail"; then
        assert_fail "echo 'Should have severity in YAML'"
    fi
    if ! echo "$output" | grep -q "  \.\.\."; then
        assert_fail "echo 'Should have YAML block end'"
    fi
}

# --- Test: TAP mode exit code 0 on all pass ---
test_tap_mode_exit_code_pass() {
    local test_file=$(create_temp_test 'test_pass() { true; }')
    local pattern=$(basename "$test_file")

    bash "$RUNNER" --tap "$pattern" > /dev/null 2>&1
    local exit_code=$?
    cleanup_temp_test "$test_file"

    assert_equals "0" "$exit_code"
}

# --- Test: TAP mode exit code 1 on failure ---
test_tap_mode_exit_code_fail() {
    local test_file=$(create_temp_test 'test_fail() { false; }')
    local pattern=$(basename "$test_file")

    bash "$RUNNER" --tap "$pattern" > /dev/null 2>&1
    local exit_code=$?
    cleanup_temp_test "$test_file"

    assert_equals "1" "$exit_code"
}

# --- Test: TAP mode suppresses default output ---
test_tap_mode_no_default_output() {
    local test_file=$(create_temp_test 'test_pass() { true; }')
    local pattern=$(basename "$test_file")

    local output=$(bash "$RUNNER" --tap "$pattern" 2>&1)
    cleanup_temp_test "$test_file"

    # Should NOT have progress bar, table, or summary
    if echo "$output" | grep -q "Running tests:"; then
        assert_fail "echo 'Should not have progress bar'"
    fi
    if echo "$output" | grep -q "| File"; then
        assert_fail "echo 'Should not have table header'"
    fi
    if echo "$output" | grep -q "Test Summary"; then
        assert_fail "echo 'Should not have summary'"
    fi
}

# --- Test: TAP + HTML combination works ---
test_tap_html_combination() {
    local test_file=$(create_temp_test 'test_pass() { true; }')
    local pattern=$(basename "$test_file")
    local html_file=$(mktemp /tmp/report_XXXXXX.html)

    local output=$(bash "$RUNNER" --tap --html "$html_file" "$pattern" 2>&1)
    cleanup_temp_test "$test_file"

    # Should have TAP output
    if ! echo "$output" | grep -q "TAP version 13"; then
        rm -f "$html_file"
        assert_fail "echo 'Should have TAP output'"
    fi

    # Should have created HTML file
    if [ ! -f "$html_file" ]; then
        assert_fail "echo 'HTML file should be created'"
    fi

    rm -f "$html_file"
}

# --- Test: TAP takes precedence over verbose ---
test_tap_verbose_precedence() {
    local test_file=$(create_temp_test 'test_pass() { true; }')
    local pattern=$(basename "$test_file")

    local output=$(bash "$RUNNER" --tap --verbose "$pattern" 2>&1)
    cleanup_temp_test "$test_file"

    # Should have TAP output, not verbose output
    if ! echo "$output" | grep -q "TAP version 13"; then
        assert_fail "echo 'Should have TAP output'"
    fi
    if echo "$output" | grep -q "Running test_pass in"; then
        assert_fail "echo 'Should not have verbose output'"
    fi
}

# --- Test: Default mode unchanged (regression) ---
test_default_mode_unchanged() {
    local test_file=$(create_temp_test 'test_pass() { true; }')
    local pattern=$(basename "$test_file")

    local output=$(bash "$RUNNER" "$pattern" 2>&1)
    cleanup_temp_test "$test_file"

    # Should NOT have TAP header
    if echo "$output" | grep -q "TAP version"; then
        assert_fail "echo 'Should not have TAP header in default mode'"
    fi

    # Should have normal summary
    if ! echo "$output" | grep -q "Test Summary"; then
        assert_fail "echo 'Should have summary in default mode'"
    fi
}

# --- Test: SKIP directive ---
test_tap_skip_directive() {
    local test_file=$(create_temp_test '
# @SKIP Database not available
test_database() { false; }
')
    local pattern=$(basename "$test_file")

    local output=$(bash "$RUNNER" --tap "$pattern" 2>&1)
    local exit_code=$?
    cleanup_temp_test "$test_file"

    # Should have SKIP in output
    if ! echo "$output" | grep -q "# SKIP"; then
        assert_fail "echo 'Should have SKIP directive in output'"
    fi

    # Skipped tests should not cause failure
    assert_equals "0" "$exit_code"
}

# --- Test: TODO directive with expected failure ---
test_tap_todo_directive_fail() {
    local test_file=$(create_temp_test '
# @TODO Known bug #123
test_known_bug() { false; }
')
    local pattern=$(basename "$test_file")

    local output=$(bash "$RUNNER" --tap "$pattern" 2>&1)
    local exit_code=$?
    cleanup_temp_test "$test_file"

    # Should have TODO in output
    if ! echo "$output" | grep -q "# TODO"; then
        assert_fail "echo 'Should have TODO directive in output'"
    fi

    # TODO failures should not cause suite failure
    assert_equals "0" "$exit_code"
}

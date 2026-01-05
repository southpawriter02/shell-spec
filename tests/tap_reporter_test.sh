#!/bin/bash
# =============================================================================
# tap_reporter_test.sh - Unit tests for TAP reporter functions
# =============================================================================

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# Source the TAP reporter and assertions
source "$SCRIPT_DIR/../src/tap_reporter.sh"
source "$SCRIPT_DIR/../src/assertions.sh"

# --- Test: tap_ok basic format ---
test_tap_ok_basic() {
    tap_reset
    tap_init > /dev/null

    local output=$(tap_ok "my test description")
    assert_equals "ok 1 - my test description" "$output"
}

# --- Test: tap_ok with directive ---
test_tap_ok_with_directive() {
    tap_reset
    tap_init > /dev/null

    local output=$(tap_ok "test with directive" "SKIP no database")
    assert_equals "ok 1 - test with directive # SKIP no database" "$output"
}

# --- Test: tap_ok increments counter ---
test_tap_ok_increments_counter() {
    tap_reset
    tap_init > /dev/null

    tap_ok "first" > /dev/null
    local output=$(tap_ok "second")
    assert_output_contains "ok 2 -" "echo '$output'"
}

# --- Test: tap_not_ok basic format ---
test_tap_not_ok_basic() {
    tap_reset
    tap_init > /dev/null

    local output=$(tap_not_ok "failed test")
    assert_output_contains "not ok 1 - failed test" "echo '$output'"
}

# --- Test: tap_not_ok with YAML block ---
test_tap_not_ok_with_yaml() {
    tap_reset
    tap_init > /dev/null

    local output=$(tap_not_ok "failed test" "Expected 1, got 2" "test.sh" "test_func" 100)

    # Check each component is present in output
    if ! echo "$output" | grep -q "not ok 1 - failed test"; then
        assert_fail "echo 'missing not ok line'"
    fi
    if ! echo "$output" | grep -q "message:"; then
        assert_fail "echo 'missing message field'"
    fi
    if ! echo "$output" | grep -q "Expected 1, got 2"; then
        assert_fail "echo 'missing error message'"
    fi
    if ! echo "$output" | grep -q "severity: fail"; then
        assert_fail "echo 'missing severity field'"
    fi
    if ! echo "$output" | grep -q "file:"; then
        assert_fail "echo 'missing file field'"
    fi
    if ! echo "$output" | grep -q "test.sh"; then
        assert_fail "echo 'missing file path'"
    fi
    if ! echo "$output" | grep -q "function:"; then
        assert_fail "echo 'missing function field'"
    fi
    if ! echo "$output" | grep -q "duration_ms: 100"; then
        assert_fail "echo 'missing duration field'"
    fi
}

# --- Test: tap_not_ok with directive skips YAML ---
test_tap_not_ok_with_directive_no_yaml() {
    tap_reset
    tap_init > /dev/null

    local output=$(tap_not_ok "todo test" "some error" "" "" 0 "TODO known issue")

    assert_output_contains "not ok 1 - todo test # TODO known issue" "echo '$output'"
    # Should NOT have YAML block when directive is present
    if echo "$output" | grep -q "  ---"; then
        assert_fail "echo 'YAML block should not be present with directive'"
    fi
}

# --- Test: tap_skip format ---
test_tap_skip_basic() {
    tap_reset
    tap_init > /dev/null

    local output=$(tap_skip "database test" "no database available")
    assert_equals "ok 1 - database test # SKIP no database available" "$output"
}

# --- Test: tap_skip without reason ---
test_tap_skip_no_reason() {
    tap_reset
    tap_init > /dev/null

    local output=$(tap_skip "skipped test")
    assert_equals "ok 1 - skipped test # SKIP" "$output"
}

# --- Test: tap_todo with passing test ---
test_tap_todo_pass() {
    tap_reset
    tap_init > /dev/null

    local output=$(tap_todo "edge case" "true" "known bug #123")
    assert_equals "ok 1 - edge case # TODO known bug #123" "$output"
}

# --- Test: tap_todo with failing test ---
test_tap_todo_fail() {
    tap_reset
    tap_init > /dev/null

    local output=$(tap_todo "edge case" "false" "known bug #123")
    assert_equals "not ok 1 - edge case # TODO known bug #123" "$output"
}

# --- Test: tap_plan format ---
test_tap_plan() {
    local output=$(tap_plan 5)
    assert_equals "1..5" "$output"
}

# --- Test: tap_plan zero ---
test_tap_plan_zero() {
    local output=$(tap_plan 0)
    assert_equals "1..0" "$output"
}

# --- Test: tap_diagnostic format ---
test_tap_diagnostic() {
    local output=$(tap_diagnostic "Starting test suite")
    assert_equals "# Starting test suite" "$output"
}

# --- Test: tap_init format ---
test_tap_init() {
    tap_reset
    local output=$(tap_init)
    assert_equals "TAP version 13" "$output"
}

# --- Test: is_tap_mode ---
test_is_tap_mode_false() {
    tap_reset
    if is_tap_mode; then
        assert_fail "echo 'TAP mode should be false after reset'"
    fi
}

test_is_tap_mode_true() {
    tap_reset
    tap_init > /dev/null
    if ! is_tap_mode; then
        assert_fail "echo 'TAP mode should be true after init'"
    fi
}

# --- Test: special character escaping ---
test_special_char_escaping() {
    tap_reset
    tap_init > /dev/null

    local output=$(tap_not_ok "test with quotes" "Expected 'hello', got 'world'" "test.sh" "test_func" 0)

    # Single quotes should be escaped as ''
    assert_output_contains "Expected ''hello'', got ''world''" "echo '$output'"
}

# --- Test: tap_get_test_number ---
test_tap_get_test_number() {
    tap_reset
    tap_init > /dev/null

    local num1=$(tap_get_test_number)
    assert_equals "0" "$num1"

    tap_ok "test" > /dev/null
    local num2=$(tap_get_test_number)
    assert_equals "1" "$num2"
}

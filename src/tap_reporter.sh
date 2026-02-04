#!/bin/bash
# =============================================================================
# tap_reporter.sh - TAP (Test Anything Protocol) v13 Reporter
# =============================================================================
#
# Part of shell-spec testing framework
# https://github.com/southpawriter02/shell-spec
#
# This module provides functions for generating TAP v13 compliant output.
# TAP is a simple text-based interface between testing modules and test
# harnesses, enabling integration with tools like prove, Jenkins, etc.
#
# Usage:
#   source tap_reporter.sh
#   tap_init
#   tap_plan 5
#   tap_ok "test passed"
#   tap_not_ok "test failed" "error message"
#
# See: https://testanything.org/tap-version-13-specification.html
# =============================================================================

# === Configuration ===
# Guard against multiple sourcing
if [[ -z "${TAP_VERSION:-}" ]]; then
    readonly TAP_VERSION="13"
fi
_TAP_TEST_NUMBER=0
_TAP_MODE=false

# === Initialization ===

# tap_init: Print TAP version header and enable TAP mode
#
# Outputs the TAP version header and initializes internal state.
# Call this once at the start of a TAP test run.
#
# Output:
#   TAP version 13
#
# Example:
#   tap_init
#
tap_init() {
    _TAP_MODE=true
    _TAP_TEST_NUMBER=0
    echo "TAP version $TAP_VERSION"
}

# tap_plan: Print test plan (call after discovery, before execution)
#
# Outputs the test plan line indicating how many tests will run.
#
# Arguments:
#   $1 - total : Total number of tests (required)
#
# Output:
#   1..N
#
# Example:
#   tap_plan 5
#
tap_plan() {
    local total="$1"
    echo "1..$total"
}

# === Test Result Functions ===

# tap_ok: Report a passing test
#
# Outputs a TAP "ok" line for a passing test.
#
# Arguments:
#   $1 - description : Test description (required)
#   $2 - directive   : TAP directive like "SKIP reason" or "TODO reason" (optional)
#
# Output:
#   ok N - description
#   ok N - description # DIRECTIVE
#
# Example:
#   tap_ok "should add numbers"
#   tap_ok "database test" "SKIP no database"
#
tap_ok() {
    local description="$1"
    local directive="${2:-}"

    ((_TAP_TEST_NUMBER++))

    if [[ -n "$directive" ]]; then
        echo "ok $_TAP_TEST_NUMBER - $description # $directive"
    else
        echo "ok $_TAP_TEST_NUMBER - $description"
    fi
}

# tap_not_ok: Report a failing test with optional YAML diagnostics
#
# Outputs a TAP "not ok" line with an optional YAML diagnostic block
# containing failure details for debugging.
#
# Arguments:
#   $1 - description  : Test description (required)
#   $2 - message      : Failure message (optional)
#   $3 - file         : Source file path (optional)
#   $4 - function     : Function name (optional)
#   $5 - duration_ms  : Test duration in milliseconds (optional, default: 0)
#   $6 - directive    : TAP directive like "TODO reason" (optional)
#
# Output:
#   not ok N - description
#     ---
#     message: 'failure message'
#     severity: fail
#     file: 'path/to/file.sh'
#     function: 'test_name'
#     duration_ms: 123
#     ...
#
# Example:
#   tap_not_ok "should handle empty input" "Expected error, got success"
#   tap_not_ok "known bug" "" "" "" 0 "TODO fix in v1.1"
#
tap_not_ok() {
    local description="$1"
    local message="${2:-}"
    local file="${3:-}"
    local func="${4:-}"
    local duration="${5:-0}"
    local directive="${6:-}"

    ((_TAP_TEST_NUMBER++))

    if [[ -n "$directive" ]]; then
        echo "not ok $_TAP_TEST_NUMBER - $description # $directive"
    else
        echo "not ok $_TAP_TEST_NUMBER - $description"
    fi

    # YAML diagnostic block (only if we have details and no directive)
    if [[ -n "$message" || -n "$file" ]] && [[ -z "$directive" ]]; then
        echo "  ---"
        if [[ -n "$message" ]]; then
            # Strip ANSI color codes and escape single quotes in message
            local clean_message=$(printf "%s" "$message" | sed 's/\x1b\[[0-9;]*m//g')
            local safe_message="${clean_message//\'/\'\'}"
            echo "  message: '$safe_message'"
        fi
        echo "  severity: fail"
        [[ -n "$file" ]] && echo "  file: '$file'"
        [[ -n "$func" ]] && echo "  function: '$func'"
        [[ "$duration" -gt 0 ]] 2>/dev/null && echo "  duration_ms: $duration"
        echo "  ..."
    fi
}

# tap_skip: Report a skipped test
#
# Outputs a TAP "ok" line with SKIP directive. Skipped tests are
# considered passing but were not actually executed.
#
# Arguments:
#   $1 - description : Test description (required)
#   $2 - reason      : Reason for skipping (optional)
#
# Output:
#   ok N - description # SKIP
#   ok N - description # SKIP reason
#
# Example:
#   tap_skip "database test" "no database available"
#
tap_skip() {
    local description="$1"
    local reason="${2:-}"

    ((_TAP_TEST_NUMBER++))

    if [[ -n "$reason" ]]; then
        echo "ok $_TAP_TEST_NUMBER - $description # SKIP $reason"
    else
        echo "ok $_TAP_TEST_NUMBER - $description # SKIP"
    fi
}

# tap_todo: Report a TODO test (expected failure is ok, unexpected pass is bonus)
#
# Outputs a TAP line with TODO directive. TODO tests that fail are expected
# and don't cause the suite to fail. TODO tests that pass are a bonus.
#
# Arguments:
#   $1 - description : Test description (required)
#   $2 - passed      : Whether the test passed ("true"/"false") (required)
#   $3 - reason      : Reason for TODO status (optional)
#
# Output:
#   ok N - description # TODO reason      (unexpected pass - bonus!)
#   not ok N - description # TODO reason  (expected failure)
#
# Example:
#   tap_todo "edge case handling" "false" "known bug #123"
#
tap_todo() {
    local description="$1"
    local passed="$2"
    local reason="${3:-}"

    ((_TAP_TEST_NUMBER++))

    local status="not ok"
    [[ "$passed" == "true" ]] && status="ok"

    if [[ -n "$reason" ]]; then
        echo "$status $_TAP_TEST_NUMBER - $description # TODO $reason"
    else
        echo "$status $_TAP_TEST_NUMBER - $description # TODO"
    fi
}

# === Utility Functions ===

# tap_diagnostic: Print a diagnostic comment
#
# Outputs a TAP diagnostic line (comment). These are informational
# and ignored by TAP parsers but useful for humans.
#
# Arguments:
#   $1 - message : Diagnostic message (required)
#
# Output:
#   # message
#
# Example:
#   tap_diagnostic "Starting database tests"
#
tap_diagnostic() {
    echo "# $1"
}

# is_tap_mode: Check if TAP mode is active
#
# Returns:
#   0 if TAP mode is active
#   1 if TAP mode is not active
#
# Example:
#   if is_tap_mode; then echo "TAP mode"; fi
#
is_tap_mode() {
    [[ "$_TAP_MODE" == "true" ]]
}

# tap_get_test_number: Get current test number (for external tracking)
#
# Output:
#   Current test number
#
# Example:
#   current=$(tap_get_test_number)
#
tap_get_test_number() {
    echo "$_TAP_TEST_NUMBER"
}

# tap_reset: Reset TAP state (useful for testing)
#
# Resets internal state to initial values.
#
tap_reset() {
    _TAP_TEST_NUMBER=0
    _TAP_MODE=false
}

#!/bin/bash
# =============================================================================
# mocking.sh - Mocking and Stubbing Library for shell-spec
# =============================================================================
#
# Part of shell-spec testing framework
# https://github.com/southpawriter02/shell-spec
#
# This module provides functions to temporarily replace system commands and
# shell functions with test doubles (mocks/stubs), enabling isolated testing.
#
# Usage:
#   source mocking.sh
#   mock_command "curl" 'echo "mocked response"'
#   stub_function "helper" 'return 0'
#   # ... run tests ...
#   unmock_all  # Called automatically by test runner
#
# Limitations:
#   - Cannot mock shell builtins (cd, export, source, exit, etc.)
#   - No call verification (spy functionality)
#   - Mocks only work for unqualified command names
#
# Compatibility: Works with Bash 3.2+ (macOS default)
#
# =============================================================================

# === State Management ===
# Track mocked commands for cleanup
_SHELL_SPEC_MOCKED_COMMANDS=()

# Track stubbed functions for cleanup
_SHELL_SPEC_STUBBED_FUNCTIONS=()

# Store original function definitions for restoration
# Using two parallel arrays instead of associative array for Bash 3.2 compatibility
_SHELL_SPEC_ORIG_FUNC_NAMES=()
_SHELL_SPEC_ORIG_FUNC_DEFS=()

# List of shell builtins that cannot be mocked
# Guard against re-declaration when sourced multiple times
if [[ -z "${_SHELL_SPEC_BUILTINS:-}" ]]; then
    _SHELL_SPEC_BUILTINS="cd export source . exit eval exec return set unset readonly declare local trap builtin command type hash read echo printf test [ ]"
fi

# === Internal Helper Functions ===

# _is_shell_builtin: Check if a command is a shell builtin
#
# Arguments:
#   $1 - command name to check
#
# Returns:
#   0 if builtin, 1 if not
#
_is_shell_builtin() {
    local cmd="$1"
    local builtin

    for builtin in $_SHELL_SPEC_BUILTINS; do
        if [[ "$cmd" == "$builtin" ]]; then
            return 0
        fi
    done

    # Also check with 'type' for any we might have missed
    if type -t "$cmd" 2>/dev/null | grep -q "builtin"; then
        return 0
    fi

    return 1
}

# _get_orig_func_index: Get the index of a function name in the original functions array
#
# Arguments:
#   $1 - function name
#
# Output:
#   Index if found, empty string if not
#
_get_orig_func_index() {
    local func_name="$1"
    local i

    for ((i=0; i<${#_SHELL_SPEC_ORIG_FUNC_NAMES[@]}; i++)); do
        if [[ "${_SHELL_SPEC_ORIG_FUNC_NAMES[$i]}" == "$func_name" ]]; then
            echo "$i"
            return 0
        fi
    done

    echo ""
    return 1
}

# _save_original_function: Save a function's definition before stubbing
#
# Arguments:
#   $1 - function name
#
# Returns:
#   0 if saved, 1 if function doesn't exist
#
_save_original_function() {
    local func_name="$1"

    if declare -f "$func_name" > /dev/null 2>&1; then
        _SHELL_SPEC_ORIG_FUNC_NAMES+=("$func_name")
        _SHELL_SPEC_ORIG_FUNC_DEFS+=("$(declare -f "$func_name")")
        return 0
    fi

    return 1
}

# _restore_function: Restore a function from saved definition
#
# Arguments:
#   $1 - function name
#
# Returns:
#   0 if restored, 1 if no saved definition
#
_restore_function() {
    local func_name="$1"
    local idx

    idx=$(_get_orig_func_index "$func_name")
    if [[ -n "$idx" ]]; then
        eval "${_SHELL_SPEC_ORIG_FUNC_DEFS[$idx]}"
        # Mark as removed by setting to empty (can't easily remove from array in Bash 3.2)
        _SHELL_SPEC_ORIG_FUNC_NAMES[$idx]=""
        _SHELL_SPEC_ORIG_FUNC_DEFS[$idx]=""
        return 0
    fi

    return 1
}

# _array_contains: Check if array contains a value
#
# Arguments:
#   $1 - value to find
#   $@ - array elements (pass as "${array[@]}")
#
# Returns:
#   0 if found, 1 if not
#
_array_contains() {
    local needle="$1"
    shift
    local element

    for element in "$@"; do
        if [[ "$element" == "$needle" ]]; then
            return 0
        fi
    done

    return 1
}

# _remove_from_mocked_commands: Remove a value from mocked commands array
#
# Arguments:
#   $1 - value to remove
#
_remove_from_mocked_commands() {
    local value="$1"
    local new_array=()
    local element

    for element in "${_SHELL_SPEC_MOCKED_COMMANDS[@]}"; do
        if [[ "$element" != "$value" ]]; then
            new_array+=("$element")
        fi
    done

    _SHELL_SPEC_MOCKED_COMMANDS=("${new_array[@]}")
}

# _remove_from_stubbed_functions: Remove a value from stubbed functions array
#
# Arguments:
#   $1 - value to remove
#
_remove_from_stubbed_functions() {
    local value="$1"
    local new_array=()
    local element

    for element in "${_SHELL_SPEC_STUBBED_FUNCTIONS[@]}"; do
        if [[ "$element" != "$value" ]]; then
            new_array+=("$element")
        fi
    done

    _SHELL_SPEC_STUBBED_FUNCTIONS=("${new_array[@]}")
}

# === Public API Functions ===

# mock_command: Replace a PATH command with a shell function
#
# Creates a shell function with the same name as the command, which takes
# precedence over PATH lookup. The function executes the provided implementation.
#
# Arguments:
#   $1 - command_name : Name of command to mock (required)
#   $2 - implementation : Shell code to execute (required)
#
# Returns:
#   0 - Success
#   1 - Error (attempted to mock a builtin)
#
# Example:
#   mock_command "curl" 'echo "mocked response"; return 0'
#   mock_command "git" 'echo "git called with: $@"'
#
mock_command() {
    local cmd_name="$1"
    local implementation="$2"

    # Validate arguments
    if [[ -z "$cmd_name" ]]; then
        echo "mock_command: command name required" >&2
        return 1
    fi

    if [[ -z "$implementation" ]]; then
        echo "mock_command: implementation required" >&2
        return 1
    fi

    # Check if it's a builtin
    if _is_shell_builtin "$cmd_name"; then
        echo "mock_command: cannot mock shell builtin '$cmd_name'" >&2
        return 1
    fi

    # Check if already mocked
    if _array_contains "$cmd_name" "${_SHELL_SPEC_MOCKED_COMMANDS[@]}"; then
        echo "mock_command: '$cmd_name' is already mocked (call unmock_command first)" >&2
        return 1
    fi

    # Track for cleanup
    _SHELL_SPEC_MOCKED_COMMANDS+=("$cmd_name")

    # Create the mock function
    # Using eval to properly handle the implementation string
    eval "${cmd_name}() { ${implementation}; }"

    # Export the function so it's available in subshells
    export -f "$cmd_name" 2>/dev/null || true

    return 0
}

# stub_function: Replace a shell function with a stub implementation
#
# Saves the original function definition (if it exists) and replaces it
# with the provided stub implementation.
#
# Arguments:
#   $1 - function_name : Name of function to stub (required)
#   $2 - implementation : Shell code to execute (required)
#
# Returns:
#   0 - Success
#   1 - Error
#
# Example:
#   stub_function "fetch_data" 'echo "stubbed data"; return 0'
#   stub_function "complex_helper" 'return 0'
#
stub_function() {
    local func_name="$1"
    local implementation="$2"

    # Validate arguments
    if [[ -z "$func_name" ]]; then
        echo "stub_function: function name required" >&2
        return 1
    fi

    if [[ -z "$implementation" ]]; then
        echo "stub_function: implementation required" >&2
        return 1
    fi

    # Check if already stubbed
    if _array_contains "$func_name" "${_SHELL_SPEC_STUBBED_FUNCTIONS[@]}"; then
        echo "stub_function: '$func_name' is already stubbed (call unstub_function first)" >&2
        return 1
    fi

    # Save original if it exists
    _save_original_function "$func_name"

    # Track for cleanup
    _SHELL_SPEC_STUBBED_FUNCTIONS+=("$func_name")

    # Create the stub function
    eval "${func_name}() { ${implementation}; }"

    return 0
}

# unmock_command: Restore a single mocked command
#
# Removes the mock function, allowing the original PATH command to be found.
#
# Arguments:
#   $1 - command_name : Name of mocked command to restore
#
# Returns:
#   0 - Success
#   1 - Command was not mocked
#
# Example:
#   unmock_command "curl"
#
unmock_command() {
    local cmd_name="$1"

    if [[ -z "$cmd_name" ]]; then
        echo "unmock_command: command name required" >&2
        return 1
    fi

    # Check if it was mocked
    if ! _array_contains "$cmd_name" "${_SHELL_SPEC_MOCKED_COMMANDS[@]}"; then
        echo "unmock_command: '$cmd_name' is not mocked" >&2
        return 1
    fi

    # Remove the function
    unset -f "$cmd_name" 2>/dev/null

    # Remove from tracking array
    _remove_from_mocked_commands "$cmd_name"

    return 0
}

# unstub_function: Restore a single stubbed function
#
# Restores the original function definition if it existed, or removes
# the stub if there was no original.
#
# Arguments:
#   $1 - function_name : Name of stubbed function to restore
#
# Returns:
#   0 - Success
#   1 - Function was not stubbed
#
# Example:
#   unstub_function "helper_func"
#
unstub_function() {
    local func_name="$1"

    if [[ -z "$func_name" ]]; then
        echo "unstub_function: function name required" >&2
        return 1
    fi

    # Check if it was stubbed
    if ! _array_contains "$func_name" "${_SHELL_SPEC_STUBBED_FUNCTIONS[@]}"; then
        echo "unstub_function: '$func_name' is not stubbed" >&2
        return 1
    fi

    # Restore original or remove stub
    if ! _restore_function "$func_name"; then
        # No original existed, just unset the stub
        unset -f "$func_name" 2>/dev/null
    fi

    # Remove from tracking array
    _remove_from_stubbed_functions "$func_name"

    return 0
}

# unmock_all: Restore all mocked commands and stubbed functions
#
# This function is called automatically by the test runner after each test
# to ensure clean state. Can also be called manually if needed.
#
# Arguments: None
#
# Returns: 0 (always succeeds)
#
# Example:
#   unmock_all
#
unmock_all() {
    local cmd
    local func
    local i

    # Restore all mocked commands
    for cmd in "${_SHELL_SPEC_MOCKED_COMMANDS[@]}"; do
        unset -f "$cmd" 2>/dev/null
    done
    _SHELL_SPEC_MOCKED_COMMANDS=()

    # Restore all stubbed functions
    for func in "${_SHELL_SPEC_STUBBED_FUNCTIONS[@]}"; do
        local idx=$(_get_orig_func_index "$func")
        if [[ -n "$idx" ]] && [[ -n "${_SHELL_SPEC_ORIG_FUNC_DEFS[$idx]:-}" ]]; then
            eval "${_SHELL_SPEC_ORIG_FUNC_DEFS[$idx]}"
        else
            unset -f "$func" 2>/dev/null
        fi
    done
    _SHELL_SPEC_STUBBED_FUNCTIONS=()
    _SHELL_SPEC_ORIG_FUNC_NAMES=()
    _SHELL_SPEC_ORIG_FUNC_DEFS=()

    return 0
}

# === Diagnostic Functions ===

# list_mocks: List all currently active mocks (for debugging)
#
# Arguments: None
#
# Output: List of mocked commands and stubbed functions
#
list_mocks() {
    if [[ ${#_SHELL_SPEC_MOCKED_COMMANDS[@]} -eq 0 ]]; then
        echo "Mocked commands: none"
    else
        echo "Mocked commands: ${_SHELL_SPEC_MOCKED_COMMANDS[*]}"
    fi

    if [[ ${#_SHELL_SPEC_STUBBED_FUNCTIONS[@]} -eq 0 ]]; then
        echo "Stubbed functions: none"
    else
        echo "Stubbed functions: ${_SHELL_SPEC_STUBBED_FUNCTIONS[*]}"
    fi
}

# is_mocked: Check if a command is currently mocked
#
# Arguments:
#   $1 - command name
#
# Returns:
#   0 if mocked, 1 if not
#
is_mocked() {
    _array_contains "$1" "${_SHELL_SPEC_MOCKED_COMMANDS[@]}"
}

# is_stubbed: Check if a function is currently stubbed
#
# Arguments:
#   $1 - function name
#
# Returns:
#   0 if stubbed, 1 if not
#
is_stubbed() {
    _array_contains "$1" "${_SHELL_SPEC_STUBBED_FUNCTIONS[@]}"
}

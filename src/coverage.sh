#!/bin/bash
# =============================================================================
# coverage.sh - Code Coverage Analysis Library for shell-spec
# =============================================================================
#
# Part of shell-spec testing framework
# https://github.com/southpawriter02/shell-spec
#
# This module provides line-by-line code coverage tracking for shell scripts.
# It uses Bash's DEBUG trap to intercept each line execution and records
# coverage data to temporary files for aggregation.
#
# IMPORTANT: This feature is EXPERIMENTAL and has known limitations:
#   - Bash 4.0+ only (not POSIX compatible)
#   - Does not track lines inside $() or <() constructs
#   - Does not track backgrounded commands (&)
#   - Performance overhead of approximately 2-5x
#
# Usage:
#   source coverage.sh
#   setup_coverage "/path/to/script.sh"
#   # ... run tests ...
#   flush_coverage
#   aggregate_coverage
#   generate_coverage_text
#
# =============================================================================

# === Version Check ===
# Coverage requires Bash 4.0+ for associative arrays and DEBUG trap in functions
if [[ "${BASH_VERSINFO[0]}" -lt 4 ]]; then
    echo "Error: Coverage requires Bash 4.0+ (current: ${BASH_VERSION})" >&2
    echo "Hint: On macOS, install newer Bash with 'brew install bash'" >&2
    return 1 2>/dev/null || exit 1
fi

# === Configuration ===
declare COVERAGE_ENABLED=false
declare COVERAGE_DIR=""
declare COVERAGE_FILE=""
declare -a COVERAGE_TARGETS=()
declare -A COVERAGE_DATA=()
declare COVERAGE_BUFFER=""
declare COVERAGE_BUFFER_SIZE=0
declare -r COVERAGE_BUFFER_FLUSH_SIZE=50

# === Setup Functions ===

# setup_coverage: Initialize coverage tracking for a test
#
# Creates temporary directory and file for coverage data collection.
# Sets up the DEBUG trap to intercept line execution.
#
# Arguments:
#   $1 - script_file : Path to script being tested (optional)
#
# Environment:
#   COVERAGE_DIR - Set to temp directory path
#   COVERAGE_FILE - Set to current coverage data file
#
# Example:
#   setup_coverage "/path/to/utils.sh"
#
setup_coverage() {
    local script_file="${1:-}"

    COVERAGE_ENABLED=true

    # Create temp directory if not exists
    if [[ -z "$COVERAGE_DIR" ]]; then
        COVERAGE_DIR=$(mktemp -d -t "shellspec_coverage_XXXXXX")
    fi

    # Create unique coverage file for this test
    local test_id="${FUNCNAME[2]:-test}_$$_$(date +%s%N 2>/dev/null || date +%s)"
    COVERAGE_FILE="$COVERAGE_DIR/${test_id}.cov"

    # Add target script to tracking list
    if [[ -n "$script_file" && -f "$script_file" ]]; then
        local abs_path
        abs_path="$(cd "$(dirname "$script_file")" 2>/dev/null && pwd)/$(basename "$script_file")"
        COVERAGE_TARGETS+=("$abs_path")
    fi

    # Reset buffer
    COVERAGE_BUFFER=""
    COVERAGE_BUFFER_SIZE=0

    # Install DEBUG trap
    # Use set -T to propagate trap to functions
    set -T
    trap '_coverage_tracker' DEBUG
}

# _coverage_tracker: DEBUG trap handler (internal)
#
# Called before each command execution. Records the source file
# and line number to the coverage buffer.
#
# Uses BASH_SOURCE and LINENO to identify the executed line.
# Buffers writes to minimize I/O overhead.
#
_coverage_tracker() {
    # Skip if coverage not enabled
    [[ "$COVERAGE_ENABLED" != "true" ]] && return

    # Get source file (caller's context)
    local source_file="${BASH_SOURCE[1]:-}"
    local line_number="${BASH_LINENO[0]:-}"

    # Skip if no source info
    [[ -z "$source_file" || -z "$line_number" ]] && return

    # Skip shell-spec internal files
    case "$source_file" in
        */coverage.sh|*/assertions.sh|*/mocking.sh|*/tap_reporter.sh|*/test_runner.sh)
            return
            ;;
    esac

    # Resolve to absolute path
    if [[ "$source_file" != /* ]]; then
        source_file="$(cd "$(dirname "$source_file")" 2>/dev/null && pwd)/$(basename "$source_file")"
    fi

    # Add to buffer
    COVERAGE_BUFFER+="${source_file}:${line_number}"$'\n'
    ((COVERAGE_BUFFER_SIZE++))

    # Flush if buffer is full
    if ((COVERAGE_BUFFER_SIZE >= COVERAGE_BUFFER_FLUSH_SIZE)); then
        _flush_buffer
    fi
}

# _flush_buffer: Write buffered coverage data to file (internal)
#
_flush_buffer() {
    if [[ -n "$COVERAGE_BUFFER" && -n "$COVERAGE_FILE" ]]; then
        printf "%s" "$COVERAGE_BUFFER" >> "$COVERAGE_FILE"
        COVERAGE_BUFFER=""
        COVERAGE_BUFFER_SIZE=0
    fi
}

# flush_coverage: Finalize coverage data for current test
#
# Writes any remaining buffered data and removes the DEBUG trap.
# Should be called at the end of each test.
#
# Example:
#   flush_coverage
#
flush_coverage() {
    # Flush remaining buffer
    _flush_buffer

    # Remove trap
    trap - DEBUG
    set +T 2>/dev/null || true
    
    COVERAGE_ENABLED=false
}

# === Aggregation Functions ===

# aggregate_coverage: Combine all coverage data from temp files
#
# Reads all .cov files in COVERAGE_DIR, deduplicates entries,
# and builds the COVERAGE_DATA associative array.
#
# Output:
#   COVERAGE_DATA["file:line"] = 1 (for each covered line)
#
# Example:
#   aggregate_coverage
#   echo "Covered files: ${!COVERAGE_DATA[@]}"
#
aggregate_coverage() {
    COVERAGE_DATA=()

    [[ -z "$COVERAGE_DIR" || ! -d "$COVERAGE_DIR" ]] && return

    # Read all coverage files
    local cov_file
    for cov_file in "$COVERAGE_DIR"/*.cov; do
        [[ -f "$cov_file" ]] || continue

        while IFS= read -r line; do
            [[ -n "$line" ]] && COVERAGE_DATA["$line"]=1
        done < "$cov_file"
    done
}

# get_coverage_stats: Calculate coverage statistics
#
# Arguments:
#   $1 - script_file : Path to script to analyze
#
# Output (to stdout):
#   Three space-separated values: executable_lines covered_lines percent
#
# Example:
#   stats=$(get_coverage_stats "src/utils.sh")
#   read total covered percent <<< "$stats"
#
get_coverage_stats() {
    local script_file="$1"
    local executable_lines=0
    local covered_lines=0
    local line_number=0

    # Resolve absolute path
    if [[ "$script_file" != /* ]]; then
        script_file="$(cd "$(dirname "$script_file")" 2>/dev/null && pwd)/$(basename "$script_file")"
    fi

    [[ ! -f "$script_file" ]] && echo "0 0 0" && return

    # Read script and count lines
    while IFS= read -r line || [[ -n "$line" ]]; do
        ((line_number++))

        if _is_executable_line "$line"; then
            ((executable_lines++))

            if [[ -n "${COVERAGE_DATA["${script_file}:${line_number}"]:-}" ]]; then
                ((covered_lines++))
            fi
        fi
    done < "$script_file"

    # Calculate percentage
    local percent=0
    if ((executable_lines > 0)); then
        percent=$(awk "BEGIN {printf \"%.1f\", ($covered_lines / $executable_lines) * 100}")
    fi

    echo "$executable_lines $covered_lines $percent"
}

# _is_executable_line: Check if a line is executable (internal)
#
# Arguments:
#   $1 - line content
#
# Returns:
#   0 if executable, 1 if not
#
_is_executable_line() {
    local line="$1"

    # Trim leading whitespace
    line="${line#"${line%%[![:space:]]*}"}"
    # Trim trailing whitespace  
    line="${line%"${line##*[![:space:]]}"}"

    # Empty line
    [[ -z "$line" ]] && return 1

    # Shebang
    [[ "$line" == "#!"* ]] && return 1

    # Comment (but not shebang)
    [[ "$line" == "#"* ]] && return 1

    # Function definition (various forms)
    [[ "$line" =~ ^[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*\(\)[[:space:]]*\{?$ ]] && return 1
    [[ "$line" =~ ^function[[:space:]]+[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*\{?$ ]] && return 1
    [[ "$line" =~ ^function[[:space:]]+[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*\(\)[[:space:]]*\{?$ ]] && return 1

    # Closing braces and keywords (standalone)
    [[ "$line" == "}" ]] && return 1
    [[ "$line" == "{" ]] && return 1
    [[ "$line" == "fi" ]] && return 1
    [[ "$line" == "done" ]] && return 1
    [[ "$line" == "esac" ]] && return 1
    [[ "$line" == "then" ]] && return 1
    [[ "$line" == "else" ]] && return 1
    [[ "$line" == "do" ]] && return 1

    return 0
}

# === Report Generation ===

# generate_coverage_text: Output text coverage report
#
# Prints a formatted coverage report to stdout.
#
# Example:
#   generate_coverage_text
#
generate_coverage_text() {
    echo ""
    echo "--- Coverage Report ---"

    local total_executable=0
    local total_covered=0

    # Get unique files from coverage data
    local -A files=()
    for key in "${!COVERAGE_DATA[@]}"; do
        local file="${key%:*}"
        files["$file"]=1
    done

    # Also include target files that may have 0% coverage
    for target in "${COVERAGE_TARGETS[@]}"; do
        files["$target"]=1
    done

    # Sort files for consistent output
    local sorted_files
    sorted_files=$(printf '%s\n' "${!files[@]}" | sort)

    # Report per file
    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        [[ -f "$file" ]] || continue

        local stats
        stats=$(get_coverage_stats "$file")
        read -r executable covered percent <<< "$stats"

        ((total_executable += executable))
        ((total_covered += covered))

        # Shorten path for display
        local display_file="$file"
        if [[ "$file" == "$PWD"/* ]]; then
            display_file=".${file#$PWD}"
        fi

        echo "Coverage: $display_file"
        echo "  Lines: ${covered}/${executable} (${percent}%)"
    done <<< "$sorted_files"

    # Total
    local total_percent=0
    if ((total_executable > 0)); then
        total_percent=$(awk "BEGIN {printf \"%.1f\", ($total_covered / $total_executable) * 100}")
    fi

    echo "─────────────────────"
    echo "Total: ${total_covered}/${total_executable} (${total_percent}%)"
}

# generate_coverage_json: Output JSON coverage report
#
# Arguments:
#   $1 - output_file : Path to write JSON (optional, defaults to stdout)
#
# Example:
#   generate_coverage_json "coverage.json"
#
generate_coverage_json() {
    local output_file="${1:-/dev/stdout}"

    local total_executable=0
    local total_covered=0

    # Build file list
    local -A files=()
    for key in "${!COVERAGE_DATA[@]}"; do
        local file="${key%:*}"
        files["$file"]=1
    done
    for target in "${COVERAGE_TARGETS[@]}"; do
        files["$target"]=1
    done

    # Start JSON
    local json='{'
    json+='"files": {'

    local first_file=true
    for file in "${!files[@]}"; do
        [[ -f "$file" ]] || continue

        $first_file || json+=','
        first_file=false

        local stats
        stats=$(get_coverage_stats "$file")
        read -r executable covered percent <<< "$stats"

        ((total_executable += executable))
        ((total_covered += covered))

        # Escape file path for JSON
        local escaped_file="${file//\\/\\\\}"
        escaped_file="${escaped_file//\"/\\\"}"

        json+="\"$escaped_file\": {"
        json+="\"total_lines\": $executable,"
        json+="\"covered_lines\": $covered,"
        json+="\"coverage_percent\": $percent,"
        json+='"lines": {'

        # Per-line coverage
        local line_number=0
        local first_line=true
        while IFS= read -r line || [[ -n "$line" ]]; do
            ((line_number++))

            if _is_executable_line "$line"; then
                $first_line || json+=','
                first_line=false

                if [[ -n "${COVERAGE_DATA["${file}:${line_number}"]:-}" ]]; then
                    json+="\"$line_number\": \"covered\""
                else
                    json+="\"$line_number\": \"uncovered\""
                fi
            fi
        done < "$file"

        json+='}}'
    done

    json+='},'

    # Summary
    local total_percent=0
    if ((total_executable > 0)); then
        total_percent=$(awk "BEGIN {printf \"%.2f\", ($total_covered / $total_executable) * 100}")
    fi

    json+='"summary": {'
    json+="\"total_lines\": $total_executable,"
    json+="\"covered_lines\": $total_covered,"
    json+="\"coverage_percent\": $total_percent"
    json+='}}'

    echo "$json" > "$output_file"
}

# check_coverage_threshold: Verify coverage meets minimum
#
# Arguments:
#   $1 - threshold : Minimum coverage percentage (0-100)
#
# Returns:
#   0 if coverage >= threshold, 1 if below
#
# Example:
#   if ! check_coverage_threshold 80; then
#       echo "Coverage below 80%!"
#       exit 1
#   fi
#
check_coverage_threshold() {
    local threshold="$1"

    local total_executable=0
    local total_covered=0

    local -A files=()
    for key in "${!COVERAGE_DATA[@]}"; do
        local file="${key%:*}"
        files["$file"]=1
    done

    for file in "${!files[@]}"; do
        [[ -f "$file" ]] || continue

        local stats
        stats=$(get_coverage_stats "$file")
        read -r executable covered percent <<< "$stats"

        ((total_executable += executable))
        ((total_covered += covered))
    done

    local total_percent=0
    if ((total_executable > 0)); then
        total_percent=$(awk "BEGIN {printf \"%.0f\", ($total_covered / $total_executable) * 100}")
    fi

    if ((total_percent < threshold)); then
        echo "Coverage ${total_percent}% is below threshold ${threshold}%" >&2
        return 1
    fi

    return 0
}

# cleanup_coverage: Remove temporary coverage files
#
# Should be called at the end of the test run.
#
# Example:
#   cleanup_coverage
#
cleanup_coverage() {
    if [[ -n "$COVERAGE_DIR" && -d "$COVERAGE_DIR" ]]; then
        rm -rf "$COVERAGE_DIR"
    fi
    COVERAGE_DIR=""
    COVERAGE_FILE=""
    COVERAGE_DATA=()
    COVERAGE_TARGETS=()
    COVERAGE_BUFFER=""
    COVERAGE_BUFFER_SIZE=0
}

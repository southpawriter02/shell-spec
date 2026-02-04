#!/bin/bash
# =============================================================================
# coverage_test.sh - Unit tests for coverage library
# =============================================================================

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# Source the assertions library
source "$SCRIPT_DIR/../src/assertions.sh"

# Helper to check if we can run coverage tests
_can_test_coverage() {
    [[ "${BASH_VERSINFO[0]}" -ge 4 ]]
}

# ============================================================================
# Tests for _is_executable_line
# ============================================================================

test_is_executable_line_simple_command() {
    if ! _can_test_coverage; then return 0; fi
    source "$SCRIPT_DIR/../src/coverage.sh"
    
    _is_executable_line 'echo "hello"'
    assert_equals 0 $? "_is_executable_line should return 0 for simple command"
}

test_is_executable_line_variable_assignment() {
    if ! _can_test_coverage; then return 0; fi
    source "$SCRIPT_DIR/../src/coverage.sh"
    
    _is_executable_line 'x=5'
    assert_equals 0 $? "_is_executable_line should return 0 for variable assignment"
}

test_is_executable_line_local_variable() {
    if ! _can_test_coverage; then return 0; fi
    source "$SCRIPT_DIR/../src/coverage.sh"
    
    _is_executable_line 'local foo="bar"'
    assert_equals 0 $? "_is_executable_line should return 0 for local variable"
}

test_is_executable_line_comment() {
    if ! _can_test_coverage; then return 0; fi
    source "$SCRIPT_DIR/../src/coverage.sh"
    
    _is_executable_line '# This is a comment'
    assert_equals 1 $? "_is_executable_line should return 1 for comment"
}

test_is_executable_line_shebang() {
    if ! _can_test_coverage; then return 0; fi
    source "$SCRIPT_DIR/../src/coverage.sh"
    
    _is_executable_line '#!/bin/bash'
    assert_equals 1 $? "_is_executable_line should return 1 for shebang"
}

test_is_executable_line_blank() {
    if ! _can_test_coverage; then return 0; fi
    source "$SCRIPT_DIR/../src/coverage.sh"
    
    _is_executable_line ''
    assert_equals 1 $? "_is_executable_line should return 1 for empty line"
}

test_is_executable_line_whitespace_only() {
    if ! _can_test_coverage; then return 0; fi
    source "$SCRIPT_DIR/../src/coverage.sh"
    
    _is_executable_line '    '
    assert_equals 1 $? "_is_executable_line should return 1 for whitespace-only line"
}

test_is_executable_line_function_definition() {
    if ! _can_test_coverage; then return 0; fi
    source "$SCRIPT_DIR/../src/coverage.sh"
    
    _is_executable_line 'my_function() {'
    assert_equals 1 $? "_is_executable_line should return 1 for function definition"
}

test_is_executable_line_function_keyword() {
    if ! _can_test_coverage; then return 0; fi
    source "$SCRIPT_DIR/../src/coverage.sh"
    
    _is_executable_line 'function my_func {'
    assert_equals 1 $? "_is_executable_line should return 1 for function keyword"
}

test_is_executable_line_closing_brace() {
    if ! _can_test_coverage; then return 0; fi
    source "$SCRIPT_DIR/../src/coverage.sh"
    
    _is_executable_line '}'
    assert_equals 1 $? "_is_executable_line should return 1 for closing brace"
}

test_is_executable_line_fi() {
    if ! _can_test_coverage; then return 0; fi
    source "$SCRIPT_DIR/../src/coverage.sh"
    
    _is_executable_line 'fi'
    assert_equals 1 $? "_is_executable_line should return 1 for fi"
}

test_is_executable_line_done() {
    if ! _can_test_coverage; then return 0; fi
    source "$SCRIPT_DIR/../src/coverage.sh"
    
    _is_executable_line 'done'
    assert_equals 1 $? "_is_executable_line should return 1 for done"
}

test_is_executable_line_esac() {
    if ! _can_test_coverage; then return 0; fi
    source "$SCRIPT_DIR/../src/coverage.sh"
    
    _is_executable_line 'esac'
    assert_equals 1 $? "_is_executable_line should return 1 for esac"
}

test_is_executable_line_then() {
    if ! _can_test_coverage; then return 0; fi
    source "$SCRIPT_DIR/../src/coverage.sh"
    
    _is_executable_line 'then'
    assert_equals 1 $? "_is_executable_line should return 1 for then"
}

test_is_executable_line_else() {
    if ! _can_test_coverage; then return 0; fi
    source "$SCRIPT_DIR/../src/coverage.sh"
    
    _is_executable_line 'else'
    assert_equals 1 $? "_is_executable_line should return 1 for else"
}

test_is_executable_line_if_statement() {
    if ! _can_test_coverage; then return 0; fi
    source "$SCRIPT_DIR/../src/coverage.sh"
    
    _is_executable_line 'if [[ $x -eq 1 ]]; then'
    assert_equals 0 $? "_is_executable_line should return 0 for if statement"
}

test_is_executable_line_while_loop() {
    if ! _can_test_coverage; then return 0; fi
    source "$SCRIPT_DIR/../src/coverage.sh"
    
    _is_executable_line 'while read line; do'
    assert_equals 0 $? "_is_executable_line should return 0 for while loop"
}

test_is_executable_line_for_loop() {
    if ! _can_test_coverage; then return 0; fi
    source "$SCRIPT_DIR/../src/coverage.sh"
    
    _is_executable_line 'for i in 1 2 3; do'
    assert_equals 0 $? "_is_executable_line should return 0 for for loop"
}

# ============================================================================
# Tests for setup and cleanup
# ============================================================================

test_setup_coverage_creates_temp_dir() {
    if ! _can_test_coverage; then return 0; fi
    source "$SCRIPT_DIR/../src/coverage.sh"
    
    setup_coverage
    
    local has_dir=0
    [[ -d "$COVERAGE_DIR" ]] && has_dir=1
    
    # Cleanup
    trap - DEBUG
    set +T 2>/dev/null || true
    cleanup_coverage
    
    assert_equals 1 "$has_dir" "setup_coverage should create temp directory"
}

test_setup_coverage_creates_coverage_file() {
    if ! _can_test_coverage; then return 0; fi
    source "$SCRIPT_DIR/../src/coverage.sh"
    
    setup_coverage
    
    local has_file_var=0
    [[ -n "$COVERAGE_FILE" ]] && has_file_var=1
    
    # Cleanup
    trap - DEBUG
    set +T 2>/dev/null || true
    cleanup_coverage
    
    assert_equals 1 "$has_file_var" "setup_coverage should set COVERAGE_FILE"
}

test_cleanup_coverage_removes_temp_dir() {
    if ! _can_test_coverage; then return 0; fi
    source "$SCRIPT_DIR/../src/coverage.sh"
    
    setup_coverage
    local temp_dir="$COVERAGE_DIR"
    
    # Cleanup
    trap - DEBUG
    set +T 2>/dev/null || true
    cleanup_coverage
    
    local dir_exists=0
    [[ -d "$temp_dir" ]] && dir_exists=1
    
    assert_equals 0 "$dir_exists" "cleanup_coverage should remove temp directory"
}

test_cleanup_coverage_resets_variables() {
    if ! _can_test_coverage; then return 0; fi
    source "$SCRIPT_DIR/../src/coverage.sh"
    
    setup_coverage
    trap - DEBUG
    set +T 2>/dev/null || true
    cleanup_coverage
    
    assert_equals "" "$COVERAGE_DIR" "cleanup_coverage should reset COVERAGE_DIR"
    assert_equals "" "$COVERAGE_FILE" "cleanup_coverage should reset COVERAGE_FILE"
}

# ============================================================================
# Tests for flush_coverage
# ============================================================================

test_flush_coverage_writes_buffer() {
    if ! _can_test_coverage; then return 0; fi
    source "$SCRIPT_DIR/../src/coverage.sh"
    
    setup_coverage
    
    # Manually add some data to buffer
    COVERAGE_BUFFER="/test/file.sh:10"$'\n'
    COVERAGE_BUFFER_SIZE=1
    
    flush_coverage
    
    local file_has_content=0
    [[ -f "$COVERAGE_FILE" ]] && [[ -s "$COVERAGE_FILE" ]] && file_has_content=1
    
    cleanup_coverage
    
    assert_equals 1 "$file_has_content" "flush_coverage should write buffer to file"
}

# ============================================================================
# Tests for aggregate_coverage
# ============================================================================

test_aggregate_coverage_combines_files() {
    if ! _can_test_coverage; then return 0; fi
    source "$SCRIPT_DIR/../src/coverage.sh"
    
    # Create temp dir with multiple cov files
    COVERAGE_DIR=$(mktemp -d)
    echo "/test/a.sh:1" > "$COVERAGE_DIR/test1.cov"
    echo "/test/b.sh:2" > "$COVERAGE_DIR/test2.cov"
    
    aggregate_coverage
    
    local count="${#COVERAGE_DATA[@]}"
    
    cleanup_coverage
    
    assert_equals 2 "$count" "aggregate_coverage should combine entries from multiple files"
}

test_aggregate_coverage_deduplicates() {
    if ! _can_test_coverage; then return 0; fi
    source "$SCRIPT_DIR/../src/coverage.sh"
    
    # Create temp dir with duplicate entries
    COVERAGE_DIR=$(mktemp -d)
    echo "/test/a.sh:1" > "$COVERAGE_DIR/test1.cov"
    echo "/test/a.sh:1" >> "$COVERAGE_DIR/test1.cov"
    echo "/test/a.sh:1" > "$COVERAGE_DIR/test2.cov"
    
    aggregate_coverage
    
    local count="${#COVERAGE_DATA[@]}"
    
    cleanup_coverage
    
    assert_equals 1 "$count" "aggregate_coverage should deduplicate entries"
}

# ============================================================================
# Tests for get_coverage_stats
# ============================================================================

test_get_coverage_stats_returns_three_values() {
    if ! _can_test_coverage; then return 0; fi
    source "$SCRIPT_DIR/../src/coverage.sh"
    
    # Create a simple test script
    local test_script=$(mktemp)
    cat > "$test_script" << 'EOF'
#!/bin/bash
echo "hello"
echo "world"
EOF
    
    # Initialize coverage data
    COVERAGE_DATA=()
    COVERAGE_DATA["$test_script:2"]=1
    
    local stats
    stats=$(get_coverage_stats "$test_script")
    
    local word_count
    word_count=$(echo "$stats" | wc -w | tr -d ' ')
    
    rm -f "$test_script"
    
    assert_equals 3 "$word_count" "get_coverage_stats should return 3 values"
}

test_get_coverage_stats_calculates_correctly() {
    if ! _can_test_coverage; then return 0; fi
    source "$SCRIPT_DIR/../src/coverage.sh"
    
    # Create a test script with 2 executable lines
    local test_script=$(mktemp)
    cat > "$test_script" << 'EOF'
#!/bin/bash
echo "hello"
echo "world"
EOF
    
    # Mark one line as covered
    COVERAGE_DATA=()
    COVERAGE_DATA["$test_script:2"]=1
    
    local stats
    stats=$(get_coverage_stats "$test_script")
    read -r total covered percent <<< "$stats"
    
    rm -f "$test_script"
    
    assert_equals 2 "$total" "Should have 2 executable lines"
    assert_equals 1 "$covered" "Should have 1 covered line"
    assert_equals "50.0" "$percent" "Coverage should be 50%"
}

# ============================================================================
# Tests for check_coverage_threshold
# ============================================================================

test_check_coverage_threshold_passes() {
    if ! _can_test_coverage; then return 0; fi
    source "$SCRIPT_DIR/../src/coverage.sh"
    
    # Create a test script with full coverage
    local test_script=$(mktemp)
    echo 'echo "hello"' > "$test_script"
    
    COVERAGE_DATA=()
    COVERAGE_DATA["$test_script:1"]=1
    
    check_coverage_threshold 80 2>/dev/null
    local result=$?
    
    rm -f "$test_script"
    
    assert_equals 0 "$result" "Threshold check should pass when coverage >= threshold"
}

test_check_coverage_threshold_fails() {
    if ! _can_test_coverage; then return 0; fi
    source "$SCRIPT_DIR/../src/coverage.sh"
    
    # Create a test script with partial coverage
    local test_script=$(mktemp)
    cat > "$test_script" << 'EOF'
echo "hello"
echo "world"
EOF
    
    COVERAGE_DATA=()
    COVERAGE_DATA["$test_script:1"]=1
    # Line 2 not covered
    
    check_coverage_threshold 80 2>/dev/null
    local result=$?
    
    rm -f "$test_script"
    
    assert_equals 1 "$result" "Threshold check should fail when coverage < threshold"
}

# ============================================================================
# Tests for generate_coverage_text
# ============================================================================

test_generate_coverage_text_output() {
    if ! _can_test_coverage; then return 0; fi
    source "$SCRIPT_DIR/../src/coverage.sh"
    
    # Create a test script
    local test_script=$(mktemp)
    echo 'echo "hello"' > "$test_script"
    
    COVERAGE_DATA=()
    COVERAGE_DATA["$test_script:1"]=1
    COVERAGE_TARGETS=("$test_script")
    
    local output
    output=$(generate_coverage_text)
    
    rm -f "$test_script"
    
    assert_output_contains "Coverage Report" "echo '$output'"
    assert_output_contains "Total:" "echo '$output'"
}

# ============================================================================
# Tests for generate_coverage_json
# ============================================================================

test_generate_coverage_json_valid() {
    if ! _can_test_coverage; then return 0; fi
    source "$SCRIPT_DIR/../src/coverage.sh"
    
    # Create a test script
    local test_script=$(mktemp)
    echo 'echo "hello"' > "$test_script"
    
    COVERAGE_DATA=()
    COVERAGE_DATA["$test_script:1"]=1
    COVERAGE_TARGETS=("$test_script")
    
    local json_file=$(mktemp)
    generate_coverage_json "$json_file"
    
    # Validate JSON with Python
    local valid=0
    python3 -c "import json; json.load(open('$json_file'))" 2>/dev/null && valid=1
    
    rm -f "$test_script" "$json_file"
    
    assert_equals 1 "$valid" "generate_coverage_json should produce valid JSON"
}

test_generate_coverage_json_has_summary() {
    if ! _can_test_coverage; then return 0; fi
    source "$SCRIPT_DIR/../src/coverage.sh"
    
    # Create a test script
    local test_script=$(mktemp)
    echo 'echo "hello"' > "$test_script"
    
    COVERAGE_DATA=()
    COVERAGE_DATA["$test_script:1"]=1
    COVERAGE_TARGETS=("$test_script")
    
    local json_file=$(mktemp)
    generate_coverage_json "$json_file"
    
    local has_summary=0
    grep -q '"summary"' "$json_file" && has_summary=1
    
    rm -f "$test_script" "$json_file"
    
    assert_equals 1 "$has_summary" "JSON should contain summary section"
}

test_generate_coverage_json_has_files() {
    if ! _can_test_coverage; then return 0; fi
    source "$SCRIPT_DIR/../src/coverage.sh"
    
    # Create a test script
    local test_script=$(mktemp)
    echo 'echo "hello"' > "$test_script"
    
    COVERAGE_DATA=()
    COVERAGE_DATA["$test_script:1"]=1
    COVERAGE_TARGETS=("$test_script")
    
    local json_file=$(mktemp)
    generate_coverage_json "$json_file"
    
    local has_files=0
    grep -q '"files"' "$json_file" && has_files=1
    
    rm -f "$test_script" "$json_file"
    
    assert_equals 1 "$has_files" "JSON should contain files section"
}

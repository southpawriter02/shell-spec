# shell-spec

[![CI](https://github.com/southpawriter02/shell-spec/actions/workflows/ci.yml/badge.svg)](https://github.com/southpawriter02/shell-spec/actions/workflows/ci.yml)

A simple, lightweight testing framework for shell scripts, written in pure shell script. It provides a test runner and an assertion library to bring a familiar xUnit/Jest-style testing experience to your shell scripting projects.

## Features

-   **Test Runner:** Discovers and runs your tests.
-   **Assertion Library:** A rich set of functions to make claims about your script's behavior.
-   **Test Isolation:** Each test function is run in a separate subshell to prevent side effects.
-   **Mocking & Stubbing:** Replace commands and functions during tests.
-   **TAP Output:** Standard Test Anything Protocol (v13) for CI integration.
-   **Code Coverage:** Line-by-line coverage tracking (Bash 4.0+ only).
-   **HTML Reports:** Rich HTML dashboard with test results and coverage.
-   **Colorized Output:** Clear and readable pass/fail messages.
-   **Pure Shell Script:** No dependencies required.

## CI/CD Status

shell-spec is automatically tested across multiple platforms and shells:

| Platform | bash | zsh | sh |
|----------|------|-----|-----|
| Ubuntu (latest) | ✅ | ✅ | ✅ |
| Ubuntu 22.04 | ✅ | ✅ | ✅ |
| macOS (latest) | ✅ | ✅ | - |
| macOS 13 | ✅ | ✅ | - |
| Alpine (musl) | - | - | ✅ |

## Getting Started

### 1. Writing Tests

Create a test file for your script. The test runner will discover any file ending in `_test.sh` by default.

A test file is a collection of functions whose names start with `test_`. Each of these functions is considered a test case.

Inside your test functions, you can use the provided assertion functions to check the behavior of your code.

**Example: `my_script_test.sh`**

```bash
#!/bin/bash

# Source the script you want to test (optional)
# source ./my_script.sh

# A simple function to be tested
add() {
  echo $(($1 + $2))
}

# --- Test Cases ---

test_addition() {
  local result
  result=$(add 2 3)
  assert_equals "5" "$result" "2 + 3 should equal 5"
}

test_command_success() {
  assert_success "echo 'hello'"
}

test_output_contains() {
  assert_output_contains "world" "echo 'hello world'"
}
```

### 2. Running Tests

To run the tests, execute the `test_runner.sh` script from the root of your project.

```bash
bash src/test_runner.sh
```

The test runner will automatically discover and run all test files in the current directory and its subdirectories.

You can also specify a custom test file pattern:

```bash
bash src/test_runner.sh "*_spec.sh"
```

## Assertion Library

The following assertion functions are available to use in your test cases.

-   `assert_equals <expected> <actual>`: Checks if two values are equal.
-   `assert_not_equals <unexpected> <actual>`: Checks if two values are not equal.
-   `assert_success <command>`: Checks if a command exits with a status code of 0.
-   `assert_fail <command>`: Checks if a command exits with a non-zero status code.
-   `assert_output_equals <command> <expected_output>`: Checks if the standard output of a command matches the expected output.
-   `assert_output_contains <command> <expected_substring>`: Checks if the standard output of a command contains a specific substring.
-   `assert_file_exists <path>`: Asserts that a file or directory exists at the given path.
-   `assert_file_not_exists <path>`: Asserts that a file or directory does not exist at the given path.
-   `assert_is_variable_set <variable_name>`: Asserts that a variable with the given name is set.
-   `assert_is_function <function_name>`: Asserts that a function with the given name is defined.

## TAP Output

shell-spec supports TAP (Test Anything Protocol) version 13 output for CI/CD integration and standardized test reporting.

### Basic Usage

```bash
# Run tests with TAP output
bash src/test_runner.sh --tap

# TAP with specific test pattern
bash src/test_runner.sh --tap "*_spec.sh"

# Combine TAP with HTML report
bash src/test_runner.sh --tap --html report.html
```

### Output Format

```
TAP version 13
1..3
ok 1 - test_addition
ok 2 - test_subtraction
not ok 3 - test_division
  ---
  message: 'Division by zero not handled'
  severity: fail
  file: './tests/math_test.sh'
  function: 'test_division'
  duration_ms: 12
  ...
```

### CI Integration

#### GitHub Actions

```yaml
- name: Run tests
  run: bash src/test_runner.sh --tap
```

#### With prove (Perl TAP harness)

```bash
prove --exec 'bash src/test_runner.sh --tap' tests/
```

### Directives

Mark tests as skipped or TODO with comment annotations:

```bash
# @SKIP Requires database connection
test_db_connection() {
    # This test will be skipped
    assert_success "psql -c 'SELECT 1'"
}

# @TODO Known issue #123
test_edge_case() {
    # This test failure won't cause the suite to fail
    assert_equals "expected" "actual"
}
```

## Mocking and Stubbing

shell-spec provides mocking and stubbing capabilities for test isolation. Mock external commands and stub shell functions to create controlled test environments.

### Mocking Commands

Use `mock_command` to replace external commands (like `curl`, `git`, `npm`) with test doubles:

```bash
test_api_call() {
    # Mock curl to return a fixed response
    mock_command "curl" 'echo "{\"status\": \"ok\"}"'

    local result=$(curl https://api.example.com/status)
    assert_equals '{"status": "ok"}' "$result"
}

test_git_operations() {
    # Mock receives all arguments via $@
    mock_command "git" 'echo "git called with: $@"'

    local output=$(git status)
    assert_output_contains "git called with: status" "echo '$output'"
}

test_command_exit_code() {
    # Mock can return specific exit codes
    mock_command "failing_cmd" 'return 1'

    failing_cmd
    assert_equals "1" "$?"
}
```

### Stubbing Functions

Use `stub_function` to replace shell functions with test implementations:

```bash
# Original function in your code
fetch_user_data() {
    curl https://api.example.com/user
}

test_with_stubbed_function() {
    # Stub the function
    stub_function "fetch_user_data" 'echo "{\"name\": \"Test User\"}"'

    local data=$(fetch_user_data)
    assert_output_contains "Test User" "echo '$data'"
}
```

### Automatic Cleanup

Mocks and stubs are automatically cleaned up after each test (tests run in subshells), ensuring isolation between tests:

```bash
test_first() {
    mock_command "mycommand" 'echo "mocked"'
    # mock exists here
}

test_second() {
    # mock from test_first does NOT exist here
    # each test starts fresh
}
```

### Manual Cleanup

For fine-grained control within a test:

```bash
test_manual_cleanup() {
    mock_command "cmd1" 'echo "one"'
    mock_command "cmd2" 'echo "two"'

    # Use the mocks...

    # Remove specific mock
    unmock_command "cmd1"

    # Remove specific stub
    unstub_function "my_func"

    # Or clear everything
    unmock_all
}
```

### Diagnostic Functions

```bash
test_diagnostics() {
    mock_command "curl" 'echo "mocked"'
    stub_function "helper" 'return 0'

    # Check if mocked/stubbed
    if is_mocked "curl"; then
        echo "curl is mocked"
    fi

    if is_stubbed "helper"; then
        echo "helper is stubbed"
    fi

    # List all active mocks (useful for debugging)
    list_mocks
    # Output:
    # Mocked commands: curl
    # Stubbed functions: helper
}
```

### Limitations

- **Cannot mock shell builtins**: Commands like `cd`, `export`, `source`, `exit`, `eval`, etc. cannot be mocked
- **Unqualified names only**: Mocks work for unqualified command names (`curl`), not full paths (`/usr/bin/curl`)
- **No spy functionality**: Currently cannot verify call counts or arguments after the fact

## Local Development

### Running Tests Locally

```bash
# Run all self-tests
./tests/run_self_tests.sh

# Run tests with a specific shell
bash src/test_runner.sh
zsh src/test_runner.sh
sh src/test_runner.sh
```

### Running ShellCheck

```bash
# Install ShellCheck (if not already installed)
brew install shellcheck  # macOS
# or: apt-get install shellcheck  # Ubuntu

# Run linting
shellcheck --rcfile=.shellcheckrc src/*.sh tests/*.sh examples/*.sh
```

### Testing Portability

```bash
# Test on Alpine Linux with Docker
docker run --rm -v "$PWD":/app -w /app alpine:latest /bin/sh src/test_runner.sh
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run the test suite: `./tests/run_self_tests.sh`
5. Run ShellCheck: `shellcheck --rcfile=.shellcheckrc src/*.sh`
6. Submit a pull request

All pull requests are automatically tested across multiple platforms and shells via GitHub Actions.

## License

MIT

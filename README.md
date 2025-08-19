# shell-spec

A simple, lightweight testing framework for shell scripts, written in pure shell script. It provides a test runner and an assertion library to bring a familiar xUnit/Jest-style testing experience to your shell scripting projects.

## Features

-   **Test Runner:** Discovers and runs your tests.
-   **Assertion Library:** A rich set of functions to make claims about your script's behavior.
-   **Test Isolation:** Each test function is run in a separate subshell to prevent side effects.
-   **Colorized Output:** Clear and readable pass/fail messages.
-   **Pure Shell Script:** No dependencies required.

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

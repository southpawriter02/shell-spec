# Feature: Assertion Library

## 1. Description

The assertion library is a collection of functions that allow test writers to check the behavior of their scripts. These functions provide a structured way to make claims about the state of the system, the output of commands, or the value of variables.

## 2. Intended Functionality

The library will be provided as a single shell script file (`assertions.sh`) that can be sourced by test files. It will include a variety of assertion functions, such as:

*   **`assert_equals <expected> <actual>`:** Checks if two strings or numbers are equal.
*   **`assert_not_equals <expected> <actual>`:** Checks if two strings or numbers are not equal.
*   **`assert_success [command]`:** Runs the given command and asserts that its exit code is 0.
*   **`assert_fail [command]`:** Runs the given command and asserts that its exit code is not 0.
*   **`assert_output_equals <expected> [command]`:** Runs the command and asserts that its standard output is equal to the expected string.
*   **`assert_output_contains <substring> [command]`:** Runs the command and asserts that its standard output contains the given substring.
*   **`assert_file_exists <path>`:** Asserts that a file or directory exists at the given path.
*   **`assert_file_not_exists <path>`:** Asserts that a file or directory does not exist at the given path.
*   **`assert_is_variable_set <variable_name>`:** Asserts that a variable with the given name is set.
*   **`assert_is_function <function_name>`:** Asserts that a function with the given name is defined.

Each assertion function will print a clear "PASS" or "FAIL" message, along with contextual information if the assertion fails (e.g., "Expected 'foo', but got 'bar'").

## 3. Requirements

*   A single file (`assertions.sh`) that can be sourced.
*   Clear and descriptive naming for assertion functions.
*   Informative output for both successful and failed assertions.
*   Should not exit the test script on failure, but rather report the failure to the test runner.

## 4. Dependencies

*   None, should be written in pure shell script.

## 5. Limitations

*   The initial version will focus on a core set of assertions. More complex assertions (e.g., for JSON output) can be added later.
*   The library will not automatically handle all edge cases of shell quoting and word splitting. Test writers will need to be careful.

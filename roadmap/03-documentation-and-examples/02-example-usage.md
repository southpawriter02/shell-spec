# Feature: Example Usage

## 1. Description

To help users understand how to use the framework, the project should include a clear, practical example of a shell script and its corresponding test file.

## 2. Intended Functionality

The project will include an `examples/` directory containing:

*   **`my_script.sh`:** A simple but non-trivial shell script that demonstrates a few common shell scripting patterns. For example, a script that takes arguments, reads from a file, and prints to standard output.
*   **`my_script_test.sh`:** A test file for `my_script.sh` that demonstrates how to use the testing framework. This test file will:
    *   Source the `assertions.sh` library.
    *   Source the script under test (`my_script.sh`).
    *   Include several test functions (e.g., `test_no_arguments`, `test_with_valid_file`, `test_with_missing_file`).
    *   Use a variety of assertion functions to check the behavior of `my_script.sh`.

This example will be referenced heavily in the `README.md` and other documentation.

## 3. Requirements

*   The example must be easy to understand.
*   The example must demonstrate best practices for using the framework.
*   The tests in the example must all pass when run with the test runner.

## 4. Dependencies

*   The example will depend on the core features of the testing framework (test runner, assertion library).

## 5. Limitations

*   The example will be simple by design. It will not attempt to cover every possible use case or feature of the framework. More complex examples could be added later as part of a larger documentation effort.

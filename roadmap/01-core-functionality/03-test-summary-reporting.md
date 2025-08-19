# Feature: Test Summary Reporting

## 1. Description

After all tests have been run, the framework should provide a clear and concise summary of the results. This is crucial for quickly understanding the health of the codebase.

## 2. Intended Functionality

*   **Counts:** The summary will display the total number of tests run, the number of tests that passed, and the number of tests that failed.
*   **Failure Details:** For each failed test, the summary will provide detailed information, including:
    *   The name of the test file where the failure occurred.
    *   The name of the test function that failed.
    *   The specific assertion that failed, along with any relevant context (e.g., expected vs. actual values).
*   **Colorized Output:** The output will use colors to improve readability. Passed tests will be marked in green, failed tests in red, and the summary will be highlighted.
*   **Exit Code:** The test runner script will exit with a code of 0 if all tests pass and a non-zero code if any tests fail. This is essential for CI/CD integration.

## 3. Requirements

*   The report must be printed to standard output.
*   The report must be easy to read and understand.
*   The test runner's exit code must reflect the test results.

## 4. Dependencies

*   None, should be written in pure shell script. The use of `tput` for colors should be done in a way that degrades gracefully if `tput` is not available.

## 5. Limitations

*   The initial version will only support text-based reporting. More advanced reporting formats (e.g., HTML, XML) are out of scope for the core functionality.

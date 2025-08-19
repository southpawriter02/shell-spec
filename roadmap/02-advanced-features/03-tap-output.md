# Feature: Test Anything Protocol (TAP) Output

## 1. Description

The Test Anything Protocol (TAP) is a simple text-based interface between testing modules and a test harness. By supporting TAP output, the shell script testing framework can integrate with a wide range of existing TAP-consuming tools for reporting and analysis.

## 2. Intended Functionality

*   **TAP-Compliant Output:** The test runner will have an option (e.g., a command-line flag `--tap`) to produce output that conforms to the TAP version 13 specification.
*   **Test Points:** Each assertion in the framework will correspond to a single test point in the TAP output. For example:
    ```
    ok 1 - should add two numbers
    not ok 2 - should fail on purpose
      ---
      message: 'Expected 5, but got 4'
      ...
    ```
*   **Plan:** The runner will print a plan at the beginning of the output, like `1..N`, where `N` is the total number of tests to be run.
*   **Directives:** The framework might support TAP directives like `# SKIP` or `# TODO` to indicate tests that are not yet implemented or are temporarily disabled.

## 3. Requirements

*   The output must be compliant with the TAP version 13 specification.
*   The TAP output option should be disabled by default to maintain the user-friendly, colorized output as the standard.
*   The integration should be seamless, with assertion functions automatically generating the correct TAP output when the mode is enabled.

## 4. Dependencies

*   None. This feature only affects the format of the standard output.

## 5. Limitations

*   The initial implementation may not support all the subtleties of the TAP specification, such as nested tests or custom YAML diagnostics.
*   It will be up to the user to install a TAP consumer (a "harness") to get the benefits of the TAP output. The framework itself will only produce the TAP stream.

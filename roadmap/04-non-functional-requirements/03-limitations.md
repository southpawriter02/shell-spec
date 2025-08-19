# Non-Functional Requirement: Limitations

## 1. Description

This document outlines the known limitations and constraints of the shell script testing framework. It is important to be transparent about what the framework *cannot* do, as this helps to set realistic expectations for users.

## 2. General Limitations

*   **Shell Script Complexity:** Shell scripting is notoriously complex, with many edge cases related to quoting, word splitting, and subshells. The framework will do its best to provide a robust testing environment, but it cannot protect the user from all the intricacies of the shell language itself.
*   **Performance:** The framework is written in pure shell script for maximum portability and ease of use. As an interpreted language, shell script is inherently slower than compiled languages. For very large test suites (thousands of tests), the performance overhead of the framework may become noticeable.
*   **No Parallelism (Initially):** The initial version of the test runner will execute tests serially (one after another). Parallel test execution is a potential future enhancement, but it adds significant complexity and is not a core goal.

## 3. Feature-Specific Limitations

*   **Mocking Built-ins:** The mocking functionality works by manipulating the `PATH` or redefining functions. This works well for external commands but is not effective for mocking shell built-in commands (e.g., `cd`, `export`, `source`, `exit`). Testing scripts that heavily rely on built-ins will be more challenging.
*   **Code Coverage Accuracy:** The code coverage feature (based on `trap DEBUG`) should be considered **experimental and potentially inaccurate**. It may not correctly report coverage for complex language constructs like process substitutions, command substitutions in `if` statements, or subshells. It provides a useful hint about untested code, but it should not be treated as a definitive metric.
*   **Windows Support:** Native support for Windows (outside of WSL) is not a goal. While the framework might work in environments like Git Bash or Cygwin, it is not tested or guaranteed.

## 4. Security Considerations

*   **Untrusted Code:** The framework is designed to test the user's own code. Like any testing tool, it operates on the assumption that the code being tested is trusted. Running the framework on untrusted or malicious shell scripts is a security risk, as the framework will execute that code. The framework itself does not add any additional security layers.

By documenting these limitations, we can guide users toward best practices and prevent them from trying to use the framework in ways that are not supported or recommended.

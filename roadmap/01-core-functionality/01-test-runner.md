# Feature: Test Runner

## 1. Description

The test runner is the heart of the framework. It's a shell script responsible for discovering, executing, and reporting on tests. It will be the main entry point for the user to run their test suite.

## 2. Intended Functionality

*   **Test Discovery:** The runner will automatically find test files within the current directory and its subdirectories. The discovery mechanism will be based on a configurable file naming convention (e.g., `*_test.sh` or `*.spec.sh`).
*   **Test Execution:** For each discovered test file, the runner will:
    *   Source the test file into a clean environment to avoid side effects between test files.
    *   Identify and execute functions within the file that are designated as tests (e.g., functions with names starting with `test_`).
*   **Isolation:** Each test function should be run in a subshell to ensure that changes to the environment (variables, functions, traps) do not affect other tests.
*   **Configuration:** The runner should be configurable via a file (e.g., `.sh-unit`) or command-line arguments to specify the test file pattern, test function prefix, and other options.

## 3. Requirements

*   Must be a standalone shell script.
*   Should be compatible with major shells like `bash` and `zsh`. POSIX compatibility is a stretch goal.
*   Must be able to discover test files recursively.
*   Must be able to execute test functions within those files.

## 4. Dependencies

*   None, should be written in pure shell script.

## 5. Limitations

*   Initial version might not support parallel test execution.
*   Complex test setup and teardown logic (e.g., `beforeEach`, `afterAll`) might not be available in the first iteration.

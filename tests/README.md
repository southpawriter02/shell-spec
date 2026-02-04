# Shell-Spec Self-Testing Suite

This directory contains the self-tests for the shell-spec testing framework. The framework tests itself ("dogfooding") to ensure all components work correctly.

## Running Self-Tests

From the project root:

```bash
./tests/run_self_tests.sh
```

To generate an HTML report:

```bash
./tests/run_self_tests.sh --html tests/selftest_report.html
```

## Test Structure

### `assertions_test.sh`
Tests for the assertion library (`src/assertions.sh`). Covers all 10 assertion functions:

| Assertion | Tests |
|-----------|-------|
| `assert_equals` | 5 tests (pass, fail, empty, numbers, special chars) |
| `assert_not_equals` | 3 tests (pass, fail, empty vs non-empty) |
| `assert_success` | 4 tests (success, fail, echo, nonexistent) |
| `assert_fail` | 3 tests (fail, success, nonexistent file) |
| `assert_output_equals` | 3 tests (pass, fail, empty output) |
| `assert_output_contains` | 3 tests (pass, fail, full match) |
| `assert_file_exists` | 3 tests (file, directory, nonexistent) |
| `assert_file_not_exists` | 2 tests (pass, fail) |
| `assert_is_variable_set` | 3 tests* (set, unset, empty string) |
| `assert_is_function` | 3 tests (defined, undefined, variable) |
| Failure messages | 2 tests (content, prefix) |

\* Note: `assert_is_variable_set` uses Bash 4.2+ features. Tests are skipped on older Bash versions.

### `runner_test.sh`
Tests for the test runner (`src/test_runner.sh`). Uses fixture files created dynamically. Covers:

- **Test Discovery**: Finding test files, ignoring non-test files, custom patterns
- **Test Execution**: Running test functions, skipping non-test functions
- **Exit Codes**: 0 for all pass, 1 for any failures
- **Summary Output**: Test counts, pass/fail labels
- **HTML Reports**: Generation and content verification
- **Test Isolation**: Variables don't leak between tests
- **Edge Cases**: No test files, empty test files

## Fixtures

The `runner_test.sh` creates temporary fixture files in `tests/fixtures/` for testing the test runner. These are automatically cleaned up after each test.

## Known Limitations

1. **Bash Version**: Some tests require Bash 4.2+ for the `-v` operator. These tests are automatically skipped on older versions.

2. **Stderr Noise**: You may see harmless errors about missing `assertions.sh` in the output. This is due to the test runner re-sourcing files in subshells and doesn't affect test results.

## CI/CD Integration

The self-tests exit with:
- `0` if all tests pass
- `1` if any tests fail

This makes them suitable for CI/CD pipelines:

```yaml
# Example GitHub Actions
- name: Run self-tests
  run: ./tests/run_self_tests.sh
```

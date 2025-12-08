# GUI/UX Enhancements for Shell-Spec

This document outlines the design and specifications for improving the user experience and reporting capabilities of the `shell-spec` framework.

## 1. Web Dashboard (HTML Reporter)

The goal is to provide a rich visual report of test results, including execution status, logs, and failure details.

### Architecture

1.  **JSON Generation**: The test runner will support a `--json` or `--report` flag that, in addition to (or instead of) printing to stdout, writes execution results to a structured JSON file.
    *   **Data Structure**:
        ```json
        {
          "summary": {
            "total": 10,
            "passed": 8,
            "failed": 2,
            "duration_ms": 120
          },
          "results": [
            {
              "file": "example_test.sh",
              "test": "test_addition",
              "status": "PASS",
              "message": "",
              "duration_ms": 5
            },
            {
              "file": "example_test.sh",
              "test": "test_failure",
              "status": "FAIL",
              "message": "Expected '5' but got '4'",
              "duration_ms": 10
            }
          ]
        }
        ```
    *   **Implementation**: Since `jq` might not be available on all minimal systems (though verified available here), the primary implementation should manually construct the JSON string to adhere to the "no dependencies" philosophy, or use `jq` if available. A safer approach for "pure shell" is to accumulate lines in a temp file and wrap them.

2.  **HTML Template**:
    *   A standalone HTML file (`report_template.html`) containing:
        *   CSS for styling (dark/light mode, status colors).
        *   A generic "Dashboard" layout.
        *   A `<script>` tag with a placeholder: `const TEST_DATA = {{TEST_DATA}};`.
        *   Client-side JavaScript to render the table and charts.
    *   The runner will read this template, replace `{{TEST_DATA}}` with the generated JSON, and save it as `report.html`.

### Usage
```bash
./src/test_runner.sh --html report.html
open report.html
```

---

## 2. CLI UX Enhancements

The goal is to make the terminal output more informative and visually appealing.

### Features

1.  **Progress Indicators**:
    *   Replace the scrolling log with a dynamic progress line: `Running tests: [=====>    ] 5/10 (50%)` using carriage return `\r`.
    *   A `--verbose` flag can restore the full scrolling log.

2.  **Summary Table**:
    *   At the end of execution, print a formatted table using `printf`.
    ```
    | File             | Test Function      | Status |
    |------------------|--------------------|--------|
    | example_test.sh  | test_addition      | PASS   |
    | example_test.sh  | test_failure       | FAIL   |
    ```

3.  **Enhanced Colors**:
    *   Use bold and distinct colors for summary stats.
    *   Make colors configurable via environment variables (e.g., `NO_COLOR`).

---

## 3. Interactive Watch Mode

The goal is to improve the development loop by automatically re-running tests when files change.

### Implementation

1.  **Polling Loop**:
    *   Use a `while` loop that sleeps for 1-2 seconds.
    *   Use `stat` (Linux) or `stat -f` (BSD/macOS) to check the modification time (`mtime`) of all `*.sh` files in the directory.
    *   Calculate a hash or sum of all mtimes.
    *   If the sum changes, trigger the test runner.

2.  **Usage**:
    ```bash
    ./src/test_runner.sh --watch
    ```

3.  **Logic**:
    ```bash
    last_checksum=""
    while true; do
      current_checksum=$(find . -name "*.sh" -exec stat -c %Y {} + | md5sum) # Simplified logic
      if [ "$current_checksum" != "$last_checksum" ]; then
        clear
        ./src/test_runner.sh
        last_checksum="$current_checksum"
      fi
      sleep 2
    done
    ```

#!/bin/bash
#
# run_self_tests.sh - Run the shell-spec framework's self-tests
#
# This script runs the framework's own test suite to verify that all
# components work correctly. It uses the framework to test itself ("dogfooding").
#
# Usage:
#   ./tests/run_self_tests.sh [--html report.html]
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TEST_RUNNER="$PROJECT_ROOT/src/test_runner.sh"

# Colors
COLOR_CYAN='\033[0;36m'
COLOR_GREEN='\033[0;32m'
COLOR_RED='\033[0;31m'
COLOR_RESET='\033[0m'

echo -e "${COLOR_CYAN}╔════════════════════════════════════════════════════════════╗${COLOR_RESET}"
echo -e "${COLOR_CYAN}║           Shell-Spec Self-Test Suite                       ║${COLOR_RESET}"
echo -e "${COLOR_CYAN}║                                                            ║${COLOR_RESET}"
echo -e "${COLOR_CYAN}║  Testing the testing framework with itself 🐕              ║${COLOR_RESET}"
echo -e "${COLOR_CYAN}╚════════════════════════════════════════════════════════════╝${COLOR_RESET}"
echo ""

# Pass through all arguments to the test runner
echo -e "${COLOR_CYAN}Running self-tests...${COLOR_RESET}"
echo ""

cd "$SCRIPT_DIR"
bash "$TEST_RUNNER" "*_test.sh" "$@"
exit_code=$?

echo ""
if [ $exit_code -eq 0 ]; then
  echo -e "${COLOR_GREEN}╔════════════════════════════════════════════════════════════╗${COLOR_RESET}"
  echo -e "${COLOR_GREEN}║  ✅ All self-tests passed! The framework is working.       ║${COLOR_RESET}"
  echo -e "${COLOR_GREEN}╚════════════════════════════════════════════════════════════╝${COLOR_RESET}"
else
  echo -e "${COLOR_RED}╔════════════════════════════════════════════════════════════╗${COLOR_RESET}"
  echo -e "${COLOR_RED}║  ❌ Some self-tests failed. Please review the output above. ║${COLOR_RESET}"
  echo -e "${COLOR_RED}╚════════════════════════════════════════════════════════════╝${COLOR_RESET}"
fi

exit $exit_code

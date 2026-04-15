#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERIFY_SCRIPT="${SCRIPT_DIR}/verify.sh"

pass_count=0
fail_count=0

run_expect_exit() {
  local name="$1"
  local expected_exit="$2"
  shift 2

  local output
  local actual_exit=0
  output="$("$@" 2>&1)" || actual_exit=$?

  if [[ "${actual_exit}" -eq "${expected_exit}" ]]; then
    echo "[PASS] ${name}"
    pass_count=$((pass_count + 1))
  else
    echo "[FAIL] ${name}"
    echo "  expected exit: ${expected_exit}, actual: ${actual_exit}"
    echo "  output: ${output}"
    fail_count=$((fail_count + 1))
  fi
}

run_expect_json_field() {
  local name="$1"
  local pattern="$2"
  shift 2

  local output
  local actual_exit=0
  output="$("$@" 2>&1)" || actual_exit=$?

  if [[ "${actual_exit}" -ne 0 ]]; then
    echo "[FAIL] ${name}"
    echo "  expected success exit, actual: ${actual_exit}"
    echo "  output: ${output}"
    fail_count=$((fail_count + 1))
    return 0
  fi

  if [[ "${output}" =~ ${pattern} ]]; then
    echo "[PASS] ${name}"
    pass_count=$((pass_count + 1))
  else
    echo "[FAIL] ${name}"
    echo "  expected pattern: ${pattern}"
    echo "  output: ${output}"
    fail_count=$((fail_count + 1))
  fi
}

main() {
  echo "Running verify input regression tests..."

  run_expect_exit \
    "none with trailing comma is accepted" \
    0 \
    bash "${VERIFY_SCRIPT}" --toolsets "none," --json

  run_expect_exit \
    "none with repeated trailing commas is accepted" \
    0 \
    bash "${VERIFY_SCRIPT}" --toolsets "none,," --json

  run_expect_exit \
    "none mixed with java is rejected" \
    1 \
    bash "${VERIFY_SCRIPT}" --toolsets "none,java" --json

  run_expect_json_field \
    "python-node and java includes missing java when absent" \
    '"name":"java","status":"missing","required":true' \
    bash "${VERIFY_SCRIPT}" --toolsets "python-node,java" --json

  run_expect_json_field \
    "none-only verify returns overall ok in json" \
    '"overall":"ok"' \
    bash "${VERIFY_SCRIPT}" --toolsets "none" --json

  echo
  echo "Test summary: ${pass_count} passed, ${fail_count} failed"

  if [[ "${fail_count}" -ne 0 ]]; then
    exit 1
  fi
}

main "$@"

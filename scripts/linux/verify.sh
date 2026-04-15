#!/usr/bin/env bash

set -euo pipefail

BASHRC_PATH="${HOME}/.bashrc"
MARKER_START="# >>> confighelper managed start >>>"
MARKER_END="# <<< confighelper managed end <<<"

check_command() {
  local cmd="$1"
  local required="${2:-false}"
  if command -v "${cmd}" >/dev/null 2>&1; then
    local path
    path="$(command -v "${cmd}")"
    echo "[OK] ${cmd}: ${path}"
    return 0
  fi

  if [[ "${required}" == "true" ]]; then
    echo "[MISSING] ${cmd} (required by selected flow)"
    return 1
  fi

  echo "[INFO] ${cmd}: not found"
  return 0
}

check_bashrc_block() {
  if [[ ! -f "${BASHRC_PATH}" ]]; then
    echo "[INFO] ${BASHRC_PATH} does not exist yet."
    return 0
  fi

  if awk -v start="${MARKER_START}" -v end="${MARKER_END}" '
    $0 == start { found_start=1 }
    $0 == end { found_end=1 }
    END { exit !(found_start && found_end) }
  ' "${BASHRC_PATH}" >/dev/null 2>&1; then
    echo "[OK] Managed ConfigHelper block found in ${BASHRC_PATH}"
  else
    echo "[WARN] Managed ConfigHelper block not found in ${BASHRC_PATH}"
  fi
}

check_shell_state() {
  if [[ -n "${GOPATH:-}" ]]; then
    echo "[OK] GOPATH in current shell: ${GOPATH}"
  else
    echo "[INFO] GOPATH not set in current shell session."
  fi
}

main() {
  local has_error=0

  echo "========================================="
  echo " ConfigHelper Linux Verify"
  echo "========================================="

  check_command "python3" || has_error=1
  check_command "node"
  check_command "java"
  check_command "go"
  check_command "kubelet"
  check_command "conda"
  check_command "docker"

  check_bashrc_block
  check_shell_state

  if [[ "${has_error}" -ne 0 ]]; then
    echo "Verify finished with issues."
    exit 1
  fi

  echo "Verify finished."
}

main "$@"

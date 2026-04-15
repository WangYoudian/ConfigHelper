#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/toolsets.sh"
source "${SCRIPT_DIR}/configure_env.sh"

TOOLSET=""
SKIP_INSTALL="false"
RUN_VERIFY="false"
VERIFY_JSON="false"
SELECTED_TOOLSETS="none"

print_header() {
  echo "========================================="
  echo " ConfigHelper Linux Bootstrap (MVP)"
  echo "========================================="
}

show_menu() {
  cat <<'EOF'
Choose toolsets to install:
  1) Python + Node.js
  2) Java
  3) Go + Kubernetes + Docker
  4) Skip installation and only run environment configuration
  0) Exit
EOF
}

usage() {
  cat <<'EOF'
Usage:
  bash scripts/linux/main.sh [options]

Options:
  --toolset <name>    Non-interactive toolset selection (repeatable or comma-separated).
                      Values: python-node | java | go-k8s-docker | none
  --skip-install      Skip Phase 1 and only run configuration.
  --verify            Run verify checks after configuration.
  --json              Output verify result in JSON format (requires --verify).
  --yes               Assume "yes" for install confirmation prompts.
  -h, --help          Show this help message.
EOF
}

append_toolset_arg() {
  local raw="$1"
  IFS=',' read -r -a parsed <<< "${raw}"
  local item
  for item in "${parsed[@]}"; do
    item="$(echo "${item}" | tr -d '[:space:]')"
    [[ -z "${item}" ]] && continue
    if [[ -z "${TOOLSET}" ]]; then
      TOOLSET="${item}"
    else
      TOOLSET="${TOOLSET},${item}"
    fi
  done
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --toolset)
        if [[ -z "${2:-}" ]]; then
          echo "Error: --toolset requires a value."
          exit 1
        fi
        append_toolset_arg "${2}"
        shift 2
        ;;
      --skip-install)
        SKIP_INSTALL="true"
        shift
        ;;
      --verify)
        RUN_VERIFY="true"
        shift
        ;;
      --json)
        VERIFY_JSON="true"
        shift
        ;;
      --yes)
        ASSUME_YES="true"
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        echo "Unknown option: $1"
        usage
        exit 1
        ;;
    esac
  done

  if [[ "${VERIFY_JSON}" == "true" && "${RUN_VERIFY}" != "true" ]]; then
    echo "Error: --json requires --verify."
    exit 1
  fi
}

run_phase_1_interactive() {
  while true; do
    show_menu
    read -rp "Your choice: " choice
    case "${choice}" in
      1)
        install_toolset "python-node"
        SELECTED_TOOLSETS="python-node"
        ;;
      2)
        install_toolset "java"
        SELECTED_TOOLSETS="java"
        ;;
      3)
        install_toolset "go-k8s-docker"
        SELECTED_TOOLSETS="go-k8s-docker"
        ;;
      4)
        install_toolset "none"
        SELECTED_TOOLSETS="none"
        ;;
      0)
        echo "Bye."
        exit 0
        ;;
      *)
        echo "Invalid choice, please try again."
        continue
        ;;
    esac
    break
  done
}

run_phase_1() {
  if [[ "${SKIP_INSTALL}" == "true" ]]; then
    echo "Skipping Phase 1 installation by flag."
    if [[ -n "${TOOLSET}" ]]; then
      SELECTED_TOOLSETS="${TOOLSET}"
    else
      SELECTED_TOOLSETS="none"
    fi
    return 0
  fi

  if [[ -n "${TOOLSET}" ]]; then
    install_toolsets "${TOOLSET}"
    SELECTED_TOOLSETS="${TOOLSET}"
    return 0
  fi

  run_phase_1_interactive
  if [[ -z "${SELECTED_TOOLSETS}" ]]; then
    SELECTED_TOOLSETS="none"
  fi
}

run_phase_2() {
  configure_env_for_detected_tools
}

run_verify() {
  if [[ "${RUN_VERIFY}" == "true" ]]; then
    local verify_args=("--toolsets" "${SELECTED_TOOLSETS}")
    if [[ "${VERIFY_JSON}" == "true" ]]; then
      verify_args+=("--json")
    fi
    bash "${SCRIPT_DIR}/verify.sh" "${verify_args[@]}"
  fi
}

main() {
  parse_args "$@"
  print_header
  echo
  echo "Phase 1: Install toolsets"
  run_phase_1
  echo
  echo "Phase 2: Configure environment and enhancements"
  run_phase_2
  echo
  run_verify
  echo
  echo "All done. Restart your shell or run: source ~/.bashrc"
}

main "$@"

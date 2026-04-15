#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/toolsets.sh"
source "${SCRIPT_DIR}/configure_env.sh"

TOOLSET=""
SKIP_INSTALL="false"
RUN_VERIFY="false"

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
  --toolset <name>    Non-interactive toolset selection.
                      Values: python-node | java | go-k8s-docker | none
  --skip-install      Skip Phase 1 and only run configuration.
  --verify            Run verify checks after configuration.
  --yes               Assume "yes" for install confirmation prompts.
  -h, --help          Show this help message.
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --toolset)
        TOOLSET="${2:-}"
        if [[ -z "${TOOLSET}" ]]; then
          echo "Error: --toolset requires a value."
          exit 1
        fi
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
}

run_phase_1_interactive() {
  while true; do
    show_menu
    read -rp "Your choice: " choice
    case "${choice}" in
      1)
        install_toolset "python-node"
        ;;
      2)
        install_toolset "java"
        ;;
      3)
        install_toolset "go-k8s-docker"
        ;;
      4)
        install_toolset "none"
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
    return 0
  fi

  if [[ -n "${TOOLSET}" ]]; then
    install_toolset "${TOOLSET}"
    return 0
  fi

  run_phase_1_interactive
}

run_phase_2() {
  configure_env_for_detected_tools
}

run_verify() {
  if [[ "${RUN_VERIFY}" == "true" ]]; then
    bash "${SCRIPT_DIR}/verify.sh"
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

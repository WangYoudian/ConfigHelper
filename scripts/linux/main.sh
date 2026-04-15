#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/toolsets.sh"
source "${SCRIPT_DIR}/configure_env.sh"

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

run_phase_1() {
  while true; do
    show_menu
    read -rp "Your choice: " choice
    case "${choice}" in
      1)
        install_python_node
        ;;
      2)
        install_java
        ;;
      3)
        install_go_k8s_docker
        ;;
      4)
        echo "Skipping Phase 1 installation."
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

run_phase_2() {
  configure_env_for_detected_tools
}

main() {
  print_header
  echo
  echo "Phase 1: Install toolsets"
  run_phase_1
  echo
  echo "Phase 2: Configure environment and enhancements"
  run_phase_2
  echo
  echo "All done. Restart your shell or run: source ~/.bashrc"
}

main "$@"

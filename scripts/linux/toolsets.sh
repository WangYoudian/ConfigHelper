#!/usr/bin/env bash

set -euo pipefail

ASSUME_YES="${ASSUME_YES:-false}"

require_sudo() {
  if ! command -v sudo >/dev/null 2>&1; then
    echo "Error: sudo is required for installation tasks."
    exit 1
  fi
}

detect_package_manager() {
  if command -v apt-get >/dev/null 2>&1; then
    echo "apt"
  elif command -v dnf >/dev/null 2>&1; then
    echo "dnf"
  elif command -v yum >/dev/null 2>&1; then
    echo "yum"
  elif command -v pacman >/dev/null 2>&1; then
    echo "pacman"
  else
    echo "unsupported"
  fi
}

install_packages() {
  local pm="$1"
  shift

  case "${pm}" in
    apt)
      sudo apt-get update
      sudo apt-get install -y "$@"
      ;;
    dnf)
      sudo dnf install -y "$@"
      ;;
    yum)
      sudo yum install -y "$@"
      ;;
    pacman)
      sudo pacman -Sy --noconfirm "$@"
      ;;
    *)
      echo "Unsupported package manager. Please install manually: $*"
      ;;
  esac
}

confirm_install() {
  local label="$1"
  if [[ "${ASSUME_YES}" == "true" ]]; then
    return 0
  fi

  read -rp "Proceed installing ${label}? [y/N]: " answer
  if [[ ! "${answer}" =~ ^[Yy]$ ]]; then
    echo "Cancelled installation for ${label}."
    return 1
  fi
}

install_python_node() {
  require_sudo
  local pm
  pm="$(detect_package_manager)"
  confirm_install "Python + Node.js" || return 0
  echo "[Phase 1] Installing Python + Node.js via ${pm}..."

  case "${pm}" in
    apt)
      install_packages "${pm}" python3 python3-pip nodejs npm
      ;;
    dnf|yum)
      install_packages "${pm}" python3 python3-pip nodejs npm
      ;;
    pacman)
      install_packages "${pm}" python python-pip nodejs npm
      ;;
    *)
      echo "Please manually install python, pip, nodejs, and npm."
      ;;
  esac
}

install_java() {
  require_sudo
  local pm
  pm="$(detect_package_manager)"
  confirm_install "Java" || return 0
  echo "[Phase 1] Installing Java via ${pm}..."

  case "${pm}" in
    apt)
      install_packages "${pm}" openjdk-17-jdk
      ;;
    dnf|yum)
      install_packages "${pm}" java-17-openjdk-devel
      ;;
    pacman)
      install_packages "${pm}" jdk17-openjdk
      ;;
    *)
      echo "Please manually install Java (OpenJDK 17+)."
      ;;
  esac
}

install_go_k8s_docker() {
  require_sudo
  local pm
  pm="$(detect_package_manager)"
  confirm_install "Go + Kubernetes + Docker" || return 0
  echo "[Phase 1] Installing Go + Kubernetes tools + Docker via ${pm}..."

  case "${pm}" in
    apt)
      install_packages "${pm}" golang-go docker.io kubelet
      ;;
    dnf|yum)
      install_packages "${pm}" golang docker kubelet
      ;;
    pacman)
      install_packages "${pm}" go docker kubelet
      ;;
    *)
      echo "Please manually install go, docker, and kubelet."
      ;;
  esac
}

install_toolset() {
  local toolset="$1"
  case "${toolset}" in
    python-node)
      install_python_node
      ;;
    java)
      install_java
      ;;
    go-k8s-docker)
      install_go_k8s_docker
      ;;
    none)
      echo "Skipping Phase 1 installation."
      ;;
    *)
      echo "Unknown toolset: ${toolset}"
      return 1
      ;;
  esac
}

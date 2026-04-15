#!/usr/bin/env bash

set -euo pipefail

require_sudo() {
  if ! command -v sudo >/dev/null 2>&1; then
    echo "Error: sudo is required for installation tasks."
    exit 1
  fi
}

detect_package_manager() {
  # detect apt-get or apt
  if command -v apt >/dev/null 2>&1; then
    echo "apt"
  elif command -v apt-get >/dev/null 2>&1; then
    echo "apt-get"
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

install_python_node() {
  require_sudo
  local pm
  pm="$(detect_package_manager)"
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

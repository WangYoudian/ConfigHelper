#!/usr/bin/env bash

set -euo pipefail

BASHRC_PATH="${HOME}/.bashrc"
MARKER_START="# >>> confighelper managed start >>>"
MARKER_END="# <<< confighelper managed end <<<"
TOOLSETS="none"
OUTPUT_JSON="false"
HAS_ERROR=0
CHECKS_JSON=""
CHECK_COUNT=0

usage() {
  cat <<'EOF'
Usage:
  bash scripts/linux/verify.sh [options]

Options:
  --toolsets <csv>  Selected toolsets. Examples: python-node,java or none
  --json            Print machine-readable JSON result
  -h, --help        Show this help message
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --toolsets)
        TOOLSETS="${2:-}"
        if [[ -z "${TOOLSETS}" ]]; then
          echo "Error: --toolsets requires a value."
          exit 1
        fi
        shift 2
        ;;
      --json)
        OUTPUT_JSON="true"
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

json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\t'/\\t}"
  echo "${s}"
}

record_check() {
  local name="$1"
  local status="$2"
  local required="$3"
  local message="$4"
  local entry

  entry="{\"name\":\"$(json_escape "${name}")\",\"status\":\"${status}\",\"required\":${required},\"message\":\"$(json_escape "${message}")\"}"
  if [[ "${CHECK_COUNT}" -eq 0 ]]; then
    CHECKS_JSON="${entry}"
  else
    CHECKS_JSON="${CHECKS_JSON},${entry}"
  fi
  CHECK_COUNT=$((CHECK_COUNT + 1))
}

check_command() {
  local cmd="$1"
  local required="${2:-false}"
  if command -v "${cmd}" >/dev/null 2>&1; then
    local path
    path="$(command -v "${cmd}")"
    if [[ "${OUTPUT_JSON}" != "true" ]]; then
      echo "[OK] ${cmd}: ${path}"
    fi
    record_check "${cmd}" "ok" "${required}" "${path}"
    return 0
  fi

  if [[ "${required}" == "true" ]]; then
    if [[ "${OUTPUT_JSON}" != "true" ]]; then
      echo "[MISSING] ${cmd} (required by selected flow)"
    fi
    record_check "${cmd}" "missing" "true" "required by selected flow"
    return 1
  fi

  if [[ "${OUTPUT_JSON}" != "true" ]]; then
    echo "[INFO] ${cmd}: not found"
  fi
  record_check "${cmd}" "info" "false" "not found"
  return 0
}

check_bashrc_block() {
  if [[ ! -f "${BASHRC_PATH}" ]]; then
    if [[ "${OUTPUT_JSON}" != "true" ]]; then
      echo "[INFO] ${BASHRC_PATH} does not exist yet."
    fi
    record_check "bashrc_managed_block" "info" "false" "${BASHRC_PATH} does not exist yet"
    return 0
  fi

  if awk -v start="${MARKER_START}" -v end="${MARKER_END}" '
    $0 == start { found_start=1 }
    $0 == end { found_end=1 }
    END { exit !(found_start && found_end) }
  ' "${BASHRC_PATH}" >/dev/null 2>&1; then
    if [[ "${OUTPUT_JSON}" != "true" ]]; then
      echo "[OK] Managed ConfigHelper block found in ${BASHRC_PATH}"
    fi
    record_check "bashrc_managed_block" "ok" "false" "Managed block found in ${BASHRC_PATH}"
  else
    if [[ "${OUTPUT_JSON}" != "true" ]]; then
      echo "[WARN] Managed ConfigHelper block not found in ${BASHRC_PATH}"
    fi
    record_check "bashrc_managed_block" "warn" "false" "Managed block not found in ${BASHRC_PATH}"
  fi
}

check_shell_state() {
  if [[ -n "${GOPATH:-}" ]]; then
    if [[ "${OUTPUT_JSON}" != "true" ]]; then
      echo "[OK] GOPATH in current shell: ${GOPATH}"
    fi
    record_check "gopath" "ok" "false" "${GOPATH}"
  else
    if [[ "${OUTPUT_JSON}" != "true" ]]; then
      echo "[INFO] GOPATH not set in current shell session."
    fi
    record_check "gopath" "info" "false" "not set in current shell session"
  fi
}

add_required_tools_for_toolset() {
  local toolset="$1"
  case "${toolset}" in
    python-node)
      REQUIRED_TOOLS+=("python3" "node")
      ;;
    java)
      REQUIRED_TOOLS+=("java")
      ;;
    go-k8s-docker)
      REQUIRED_TOOLS+=("go" "kubelet" "docker")
      ;;
    none)
      ;;
    *)
      echo "Error: unknown toolset '${toolset}'"
      exit 1
      ;;
  esac
}

build_required_tools() {
  local raw
  IFS=',' read -r -a toolset_items <<< "${TOOLSETS}"
  REQUIRED_TOOLS=()
  local dedup=","
  local has_none="false"
  local has_non_none="false"

  for raw in "${toolset_items[@]}"; do
    local normalized
    normalized="$(echo "${raw}" | tr -d '[:space:]')"
    [[ -z "${normalized}" ]] && continue

    # Track semantic presence instead of raw array length because trailing commas
    # can introduce empty elements (e.g. "none," or "none,,").
    if [[ "${normalized}" == "none" ]]; then
      has_none="true"
    else
      has_non_none="true"
    fi

    add_required_tools_for_toolset "${normalized}"
  done

  if [[ "${has_none}" == "true" && "${has_non_none}" == "true" ]]; then
    echo "Error: toolset 'none' cannot be combined with others."
    exit 1
  fi

  UNIQUE_REQUIRED_TOOLS=()
  local cmd
  for cmd in "${REQUIRED_TOOLS[@]}"; do
    if [[ "${dedup}" == *",${cmd},"* ]]; then
      continue
    fi
    dedup+="${cmd},"
    UNIQUE_REQUIRED_TOOLS+=("${cmd}")
  done
}

print_json_result() {
  local overall="ok"
  if [[ "${HAS_ERROR}" -ne 0 ]]; then
    overall="error"
  fi

  printf '{"overall":"%s","toolsets":"%s","checks":[%s]}\n' \
    "${overall}" \
    "$(json_escape "${TOOLSETS}")" \
    "${CHECKS_JSON}"
}

main() {
  parse_args "$@"
  build_required_tools

  if [[ "${OUTPUT_JSON}" != "true" ]]; then
    echo "========================================="
    echo " ConfigHelper Linux Verify"
    echo "========================================="
    echo "Selected toolsets: ${TOOLSETS}"
  fi

  local cmd
  for cmd in "${UNIQUE_REQUIRED_TOOLS[@]}"; do
    check_command "${cmd}" "true" || HAS_ERROR=1
  done

  check_bashrc_block
  check_shell_state

  if [[ "${OUTPUT_JSON}" == "true" ]]; then
    print_json_result
  elif [[ "${HAS_ERROR}" -ne 0 ]]; then
    echo "Verify finished with issues."
    exit 1
  else
    echo "Verify finished."
  fi
}

main "$@"

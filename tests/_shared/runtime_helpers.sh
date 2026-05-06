#!/usr/bin/env bash
set -euo pipefail

validator_multiarch() {
  if command -v dpkg-architecture >/dev/null 2>&1; then
    dpkg-architecture -qDEB_HOST_MULTIARCH
  else
    gcc -print-multiarch
  fi
}

validator_require_file() {
  local path=$1
  [[ -f "$path" ]] || {
    printf 'missing required file: %s\n' "$path" >&2
    exit 1
  }
}

validator_require_dir() {
  local path=$1
  [[ -d "$path" ]] || {
    printf 'missing required directory: %s\n' "$path" >&2
    exit 1
  }
}

validator_assert_contains() {
  local path=$1
  local needle=$2
  grep -Fq -- "$needle" "$path" || {
    printf 'expected %s to contain: %s\n' "$path" "$needle" >&2
    if [[ -f "$path" ]]; then
      sed -n '1,120p' "$path" >&2
    fi
    exit 1
  }
}

validator_make_fixture() {
  local path=$1
  mkdir -p "$(dirname "$path")"
  if (($# > 1)); then
    printf '%s' "$2" >"$path"
  else
    cat >"$path"
  fi
}

validator_run_xvfb() {
  if command -v xvfb-run >/dev/null 2>&1; then
    xvfb-run -a "$@"
  else
    "$@"
  fi
}

validator_status_dir() {
  printf '%s\n' "${VALIDATOR_STATUS_DIR:-/validator/status}"
}

validator_mark_status() {
  local name=$1
  local status_dir
  status_dir=$(validator_status_dir)
  mkdir -p "$status_dir"
  : >"$status_dir/$name"
}

validator_copy_tree() {
  local source=$1
  local dest=$2
  mkdir -p "$(dirname "$dest")"
  cp -a "$source" "$dest"
}

validator_copy_file() {
  local source=$1
  local dest=$2
  mkdir -p "$(dirname "$dest")"
  cp -a "$source" "$dest"
}

validator_make_tool_shims() {
  local dest_dir=$1
  shift

  mkdir -p "$dest_dir"
  while (($#)); do
    local tool=$1
    local target
    shift

    target=$(command -v "$tool") || {
      printf 'missing required command: %s\n' "$tool" >&2
      exit 1
    }
    ln -sf "$target" "$dest_dir/$tool"
  done
}

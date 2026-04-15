#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: $0 <implement-phase-id>" >&2
  exit 64
}

[[ $# -eq 1 ]] || usage

phase_id="$1"
subject="$(git log -1 --format=%s)"

case "${subject}" in
  "${phase_id}"*)
    ;;
  *)
    echo "expected HEAD subject to begin with ${phase_id}, got: ${subject}" >&2
    exit 1
    ;;
esac

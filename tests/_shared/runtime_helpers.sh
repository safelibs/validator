#!/usr/bin/env bash
set -euo pipefail
validator_assert_contains() {
  local path=$1 needle=$2
  grep -Fq -- "$needle" "$path" || { echo "MISSING: $needle in $path"; cat "$path"; exit 1; }
}

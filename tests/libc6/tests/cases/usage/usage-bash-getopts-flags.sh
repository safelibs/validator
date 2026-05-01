#!/usr/bin/env bash
# @testcase: usage-bash-getopts-flags
# @title: bash getopts builtin flag parsing
# @description: Drives the bash getopts builtin through a short-option string with an argument-bearing flag and a boolean flag, asserting OPTIND advances correctly.
# @timeout: 120
# @tags: usage, shell, libc
# @client: bash

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bash-getopts-flags"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

bash >"$tmpdir/out" <<'BASH_EOF'
set -- -v -f payload.txt rest
verbose=0
file=
while getopts ":vf:" opt; do
  case "$opt" in
    v) verbose=1 ;;
    f) file=$OPTARG ;;
    *) echo "bad opt: $opt" >&2; exit 2 ;;
  esac
done
shift $((OPTIND - 1))
printf 'verbose=%d file=%s rest=%s optind=%d\n' "$verbose" "$file" "$1" "$OPTIND"
BASH_EOF

validator_assert_contains "$tmpdir/out" 'verbose=1 file=payload.txt rest=rest optind=4'

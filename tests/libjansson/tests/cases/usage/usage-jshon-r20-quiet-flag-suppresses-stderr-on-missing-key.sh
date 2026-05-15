#!/usr/bin/env bash
# @testcase: usage-jshon-r20-quiet-flag-suppresses-stderr-on-missing-key
# @title: jshon -Q -e missing emits empty stderr and a non-zero exit on a missing key
# @description: Pipes {"a":1} through jshon -Q -e nonexistent capturing stderr, asserts the captured stderr is empty (quiet mode suppresses the diagnostic), and asserts the exit status is non-zero, exercising libjansson's lookup-miss path through jshon's quiet error-suppression flag.
# @timeout: 30
# @tags: usage, json, cli, quiet, error, missing-key, r20
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

set +e
printf '{"a":1}' | jshon -Q -e nonexistent >"$tmpdir/out.txt" 2>"$tmpdir/err.txt"
rc=$?
set -e

[[ "$rc" -ne 0 ]] || { printf 'expected nonzero exit, got %s\n' "$rc" >&2; exit 1; }
err_size=$(wc -c <"$tmpdir/err.txt")
[[ "$err_size" -eq 0 ]] || { printf 'expected empty stderr, got %s bytes\n' "$err_size" >&2; cat "$tmpdir/err.txt" >&2; exit 1; }

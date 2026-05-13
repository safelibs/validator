#!/usr/bin/env bash
# @testcase: usage-bzip2-r16-help-mentions-compression-levels
# @title: bzip2 --help output mentions compression and decompression options
# @description: Runs bzip2 --help and asserts the usage banner mentions both "compress" and "decompress" tokens, locking in the user-facing help text shape without depending on column layout or exact wording.
# @timeout: 30
# @tags: usage, bzip2, help, banner
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# bzip2 --help writes to stderr and exits 0 when no input is on stdin
bzip2 --help </dev/null >"$tmpdir/stdout" 2>"$tmpdir/stderr" || true
cat "$tmpdir/stdout" "$tmpdir/stderr" | tr '[:upper:]' '[:lower:]' >"$tmpdir/all"

validator_assert_contains "$tmpdir/all" 'compress'
validator_assert_contains "$tmpdir/all" 'decompress'

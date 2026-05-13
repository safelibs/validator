#!/usr/bin/env bash
# @testcase: usage-bzip2-r16-version-banner-shape
# @title: bzip2 --version banner mentions program name and version year string
# @description: Runs bzip2 --version and asserts the banner names the program and includes a "Copyright" line, locking in the upstream banner shape that the Ubuntu 24.04 bzip2 emits without committing to a specific version number.
# @timeout: 30
# @tags: usage, bzip2, version, banner
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# bzip2 writes --version banner to stderr and exits 0 when no input is provided
# on stdin; capture stderr but tolerate a non-zero exit from the empty stdin path
# by piping in /dev/null.
bzip2 --version </dev/null >"$tmpdir/stdout" 2>"$tmpdir/stderr" || true

cat "$tmpdir/stdout" "$tmpdir/stderr" >"$tmpdir/all"
validator_assert_contains "$tmpdir/all" 'bzip2'
validator_assert_contains "$tmpdir/all" 'Copyright'

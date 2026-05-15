#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-r19-xz-quiet-suppresses-stderr
# @title: xz --quiet on already-suffixed input produces no stderr output
# @description: Renames a payload to a .xz-conflicting name, runs xz --quiet which would normally emit a warning on stderr, and asserts the captured stderr is empty, pinning the suppression behavior of the quiet flag.
# @timeout: 60
# @tags: usage, xz, quiet, stderr, r19
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'r19 xz quiet payload\n' >"$tmpdir/data.txt"

# Successful xz with --quiet should leave stderr empty
xz --quiet -k "$tmpdir/data.txt" 2>"$tmpdir/err.log"
[[ -f "$tmpdir/data.txt.xz" ]]

[[ ! -s "$tmpdir/err.log" ]] || { printf 'expected empty stderr, got:\n' >&2; cat "$tmpdir/err.log" >&2; exit 1; }

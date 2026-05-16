#!/usr/bin/env bash
# @testcase: usage-jshon-r21-f-flag-missing-file-error
# @title: jshon -F on a non-existent path exits nonzero with a stderr file-error message
# @description: Runs jshon -F /nonexistent/path against an unwritable path that cannot exist, captures stderr, asserts the exit code is nonzero and that the captured stderr contains both "unable to read file" and the literal target path - locking in libjansson-backed jshon's file-mode error reporting when the requested input is missing.
# @timeout: 30
# @tags: usage, json, cli, file-mode, error, r21
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

target="$tmpdir/does-not-exist-r21.json"
[[ ! -e "$target" ]] || { echo 'unexpected pre-existing target' >&2; exit 1; }

set +e
jshon -F "$target" -t >"$tmpdir/out" 2>"$tmpdir/err"
rc=$?
set -e

[[ $rc -ne 0 ]] || { echo 'expected non-zero exit for missing file' >&2; cat "$tmpdir/out" "$tmpdir/err" >&2; exit 1; }
validator_assert_contains "$tmpdir/err" 'unable to read file'
validator_assert_contains "$tmpdir/err" "$target"

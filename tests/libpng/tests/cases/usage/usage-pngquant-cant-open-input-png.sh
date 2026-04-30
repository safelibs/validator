#!/usr/bin/env bash
# @testcase: usage-pngquant-cant-open-input-png
# @title: pngquant missing input exit 2
# @description: Confirms pngquant returns exit code 2 when the input PNG path cannot be opened, and writes no output file.
# @timeout: 60
# @tags: usage, image, png
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

missing="$tmpdir/does-not-exist.png"
[[ ! -e "$missing" ]]

set +e
pngquant --force --output "$tmpdir/out.png" 16 "$missing" 2>"$tmpdir/err"
status=$?
set -e

# pngquant on Ubuntu 24.04 maps "input file cannot be opened" to exit code 2
# (READ_ERROR). 98 is the write-side I/O error code and does not apply here.
printf 'pngquant exit=%s\n' "$status" | tee "$tmpdir/status"
validator_assert_contains "$tmpdir/status" 'pngquant exit=2'
[[ ! -e "$tmpdir/out.png" ]]

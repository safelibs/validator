#!/usr/bin/env bash
# @testcase: usage-gio-remove-multiple-files
# @title: gio remove deletes multiple files in one invocation
# @description: Removes several files at once with gio remove --force and verifies every target is gone.
# @timeout: 180
# @tags: usage, gio, filesystem
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-remove-multiple-files"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'first\n' >"$tmpdir/one.txt"
printf 'second\n' >"$tmpdir/two.txt"
printf 'third\n' >"$tmpdir/three.txt"

gio remove --force "$tmpdir/one.txt" "$tmpdir/two.txt" "$tmpdir/three.txt"

test ! -e "$tmpdir/one.txt"
test ! -e "$tmpdir/two.txt"
test ! -e "$tmpdir/three.txt"

# --force on a missing file must succeed silently as well.
gio remove --force "$tmpdir/one.txt"

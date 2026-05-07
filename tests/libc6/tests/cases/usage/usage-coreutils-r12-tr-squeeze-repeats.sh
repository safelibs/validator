#!/usr/bin/env bash
# @testcase: usage-coreutils-r12-tr-squeeze-repeats
# @title: coreutils tr -s squeezes runs of a character class
# @description: Pipes a string with runs of spaces through tr -s ' ' under LC_ALL=C and verifies consecutive spaces collapse to a single space.
# @timeout: 60
# @tags: usage, coreutils, tr
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'one    two\tthree   four\n' >"$tmpdir/in.txt"
LC_ALL=C tr -s ' ' <"$tmpdir/in.txt" >"$tmpdir/got.txt"
got=$(cat "$tmpdir/got.txt")
[[ "$got" == $'one two\tthree four' ]]

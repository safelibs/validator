#!/usr/bin/env bash
# @testcase: usage-coreutils-r14-cut-output-delimiter
# @title: coreutils cut --output-delimiter rewrites the delimiter between selected fields
# @description: Pipes a colon-delimited record through cut -d: -f1,3,5 --output-delimiter='|' under LC_ALL=C and asserts the selected fields are joined with the new pipe delimiter while the unselected fields are dropped.
# @timeout: 60
# @tags: usage, coreutils, cut
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'a:b:c:d:e\n' >"$tmpdir/in.txt"
LC_ALL=C cut -d: -f1,3,5 --output-delimiter='|' "$tmpdir/in.txt" >"$tmpdir/got.txt"

got=$(cat "$tmpdir/got.txt")
[[ "$got" == "a|c|e" ]]

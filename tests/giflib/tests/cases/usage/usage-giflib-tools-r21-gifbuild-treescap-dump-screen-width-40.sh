#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r21-gifbuild-treescap-dump-screen-width-40
# @title: gifbuild -d on treescap.gif dump contains exactly one "screen width 40" line
# @description: Runs gifbuild -d on treescap.gif and asserts the dump contains exactly one line matching the literal "screen width 40" (treescap is 40x40 single-screen-descriptor), exercising the gifbuild dump screen-width emission uniqueness on the treescap fixture distinct from prior screen-width tests that did not check uniqueness.
# @timeout: 60
# @tags: usage, cli, gifbuild, screen-width, r21
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

gifbuild -d "$gif" >"$tmpdir/dump.txt"
count=$(grep -cE '^[[:space:]]*screen width 40[[:space:]]*$' "$tmpdir/dump.txt" || true)
[[ "$count" == "1" ]] || { printf 'expected exactly 1 "screen width 40" line, got %s\n' "$count" >&2; exit 1; }

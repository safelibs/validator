#!/usr/bin/env bash
# @testcase: usage-bzip2-r20-bzip2-help-shows-block-size-flag
# @title: bzip2 --help output mentions the --best long option
# @description: Runs bzip2 --help and asserts the captured help text contains the literal substring "--best" since the help banner lists long-option aliases for compression-level shortcuts, exercising help-banner content distinct from prior version-line or compression-levels-mention tests.
# @timeout: 15
# @tags: usage, bzip2, help, long-flag, r20
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

bzip2 --help >"$tmpdir/help.txt" 2>&1 || true
[[ -s "$tmpdir/help.txt" ]] || { printf 'help output empty\n' >&2; exit 1; }
validator_assert_contains "$tmpdir/help.txt" '--best'

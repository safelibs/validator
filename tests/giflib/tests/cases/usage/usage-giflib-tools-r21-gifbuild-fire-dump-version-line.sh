#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r21-gifbuild-fire-dump-version-line
# @title: gifbuild -d on fire.gif dump first non-comment line contains the screen width directive
# @description: Runs gifbuild -d on fire.gif and asserts the first non-comment non-blank line is exactly "screen width 30", exercising the gifbuild dump structural shape that opens with the screen-descriptor directive on fire distinct from prior screen-size-line tests that only checked presence anywhere in the dump.
# @timeout: 60
# @tags: usage, cli, gifbuild, dump-shape, r21
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

gifbuild -d "$gif" >"$tmpdir/dump.txt"

first=$(awk '!/^#/ && NF { print; exit }' "$tmpdir/dump.txt")
[[ "$first" == "screen width 30" ]] || { printf 'expected first directive "screen width 30", got %q\n' "$first" >&2; sed -n '1,10p' "$tmpdir/dump.txt" >&2; exit 1; }

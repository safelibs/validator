#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r16-giftext-treescap-colormap-rows-256
# @title: giftext -c treescap.gif emits the Global Color Map header for a 256-entry palette
# @description: Runs giftext -c on treescap.gif and asserts the dump contains the literal "Global Color Map" header banner and that the body contains at least 200 hex-like color tuples of the form "rr gg bb", exercising giftext's colormap renderer on the 256-entry palette without assuming exact line layout.
# @timeout: 60
# @tags: usage, cli, giftext, colormap
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

giftext -c "$gif" >"$tmpdir/c.txt"
[[ -s "$tmpdir/c.txt" ]]

validator_assert_contains "$tmpdir/c.txt" 'Global Color Map'

# Count "rr gg bb"-style hex triples (lower or upper case). 256-entry palette
# should surface well over 200 such triples regardless of giftext's row
# bundling on this giflib version.
tuples=$(grep -oE '[0-9a-fA-F]{2} [0-9a-fA-F]{2} [0-9a-fA-F]{2}' "$tmpdir/c.txt" | wc -l)
(( tuples >= 200 )) || {
    printf 'expected >= 200 hex tuples in giftext -c output, got %s\n' "$tuples" >&2
    sed -n '1,40p' "$tmpdir/c.txt" >&2
    exit 1
}

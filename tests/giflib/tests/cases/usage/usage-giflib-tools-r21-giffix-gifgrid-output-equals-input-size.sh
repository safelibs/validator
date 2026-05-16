#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r21-giffix-gifgrid-output-equals-input-size
# @title: giffix on gifgrid.gif produces output of the same byte size as the input
# @description: Runs giffix on the clean gifgrid.gif fixture and asserts the output file size equals the input file size (giffix downgrades the version magic but does not add/remove payload bytes on a clean input), exercising the giffix output-size invariant on gifgrid distinct from prior frame-count-preserved and trailing-junk-clean tests on other fixtures.
# @timeout: 60
# @tags: usage, cli, giffix, noop, r21
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/gifgrid.gif"
validator_require_file "$gif"

giffix "$gif" >"$tmpdir/out.gif"

in_size=$(stat -c '%s' "$gif")
out_size=$(stat -c '%s' "$tmpdir/out.gif")
[[ "$in_size" == "$out_size" ]] || { printf 'sizes differ: %s vs %s\n' "$in_size" "$out_size" >&2; exit 1; }

file "$tmpdir/out.gif" | grep -q 'GIF image data'

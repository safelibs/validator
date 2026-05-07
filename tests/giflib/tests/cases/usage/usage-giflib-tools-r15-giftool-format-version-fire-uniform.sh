#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r15-giftool-format-version-fire-uniform
# @title: giftool -f %v reports a single uniform GIF version across all fire.gif frames
# @description: Runs giftool -f '%v\n' against fire.gif and asserts the deduplicated version string is exactly one value (GIF87a or GIF89a) — i.e. giftool reports the same file-level version on every frame line, exercising the per-frame version cookie's uniformity invariant.
# @timeout: 60
# @tags: usage, cli, giftool, format
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

giftool -f '%v\n' <"$gif" >"$tmpdir/v.txt"
[[ -s "$tmpdir/v.txt" ]]

unique_count=$(sort -u "$tmpdir/v.txt" | wc -l)
[[ "$unique_count" -eq 1 ]] || {
    printf 'expected single uniform version, got:\n' >&2
    sort -u "$tmpdir/v.txt" >&2
    exit 1
}

unique=$(sort -u "$tmpdir/v.txt")
if [[ "$unique" != "GIF87a" && "$unique" != "GIF89a" ]]; then
    printf 'unexpected version string: %s\n' "$unique" >&2
    exit 1
fi

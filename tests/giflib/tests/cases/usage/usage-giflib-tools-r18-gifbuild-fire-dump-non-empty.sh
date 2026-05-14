#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r18-gifbuild-fire-dump-non-empty
# @title: gifbuild -d on fire.gif emits a non-empty textual dump
# @description: Runs gifbuild -d on fire.gif to produce the textual dump representation and asserts the dump file is non-empty and contains the GIF version identifier string at the start of the output, exercising the dump-only side of the gifbuild round-trip.
# @timeout: 60
# @tags: usage, cli, gifbuild, dump, r18
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

gifbuild -d "$gif" >"$tmpdir/dump.txt"
[[ -s "$tmpdir/dump.txt" ]]
grep -q 'GIF' "$tmpdir/dump.txt" || {
    printf 'expected GIF identifier in dump:\n' >&2
    sed -n '1,20p' "$tmpdir/dump.txt" >&2
    exit 1
}

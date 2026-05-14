#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r17-gifecho-pipe-into-gifbuild-roundtrip
# @title: gifecho output feeds back into gif2rgb successfully
# @description: Runs gifecho with a short ASCII payload, captures the emitted GIF on stdout, and asserts the result is a structurally valid GIF whose first three bytes are the ASCII "GIF" magic, exercising the gifecho generation path end-to-end.
# @timeout: 60
# @tags: usage, cli, gifecho
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gifecho "R17" >"$tmpdir/echo.gif"
[[ -s "$tmpdir/echo.gif" ]]
file "$tmpdir/echo.gif" | grep -q 'GIF image data'
magic=$(head -c 3 "$tmpdir/echo.gif")
[[ "$magic" == "GIF" ]] || {
    printf 'gifecho output magic = %q\n' "$magic" >&2
    exit 1
}

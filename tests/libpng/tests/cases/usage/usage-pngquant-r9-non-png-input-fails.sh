#!/usr/bin/env bash
# @testcase: usage-pngquant-r9-non-png-input-fails
# @title: pngquant rejects non-PNG input
# @description: Feeds a small text file to pngquant and verifies the binary exits non-zero, treating non-PNG input as an error.
# @timeout: 60
# @tags: usage, image, png
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'this is not a png\n' >"$tmpdir/notapng.png"

set +e
pngquant --force --output "$tmpdir/out.png" 256 "$tmpdir/notapng.png" >"$tmpdir/stdout.log" 2>"$tmpdir/stderr.log"
rc=$?
set -e

[[ "$rc" -ne 0 ]] || { printf 'pngquant accepted non-PNG input\n' >&2; exit 1; }
[[ ! -s "$tmpdir/out.png" ]] || {
  # pngquant should not have created a usable output; if it did, that would be wrong.
  if file "$tmpdir/out.png" | grep -q 'PNG image data'; then
    printf 'pngquant produced a PNG from non-PNG input\n' >&2; exit 1;
  fi
}

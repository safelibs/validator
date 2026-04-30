#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giffix-truncated-trailer
# @title: giffix tolerates trailing junk after GIF trailer
# @description: Appends junk bytes after the GIF trailer of a fixture, runs giffix to clean the stream, and confirms giftext can still parse the screen descriptor on the repaired output.
# @timeout: 60
# @tags: usage, cli, giffix, repair
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

orig_size=$(wc -c <"$gif")

# Append 32 junk bytes after the GIF trailer (0x3B). A GIF decoder must stop
# at the trailer, so giffix should still produce a valid GIF; this tests
# giffix's ability to normalise a stream with trailing garbage.
cp "$gif" "$tmpdir/dirty.gif"
head -c 32 /dev/urandom >>"$tmpdir/dirty.gif"
[[ "$(wc -c <"$tmpdir/dirty.gif")" -eq "$(( orig_size + 32 ))" ]]

giffix "$tmpdir/dirty.gif" >"$tmpdir/fixed.gif"
file "$tmpdir/fixed.gif" | grep -q 'GIF image data'

# The fixed file must be no larger than the original (junk trimmed) and must
# still parse cleanly with giftext, including the screen descriptor.
fixed_size=$(wc -c <"$tmpdir/fixed.gif")
if (( fixed_size > orig_size )); then
  printf 'expected fixed.gif (%d) to be <= orig (%d)\n' "$fixed_size" "$orig_size" >&2
  exit 1
fi

giftext "$tmpdir/fixed.gif" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" 'Screen Size'

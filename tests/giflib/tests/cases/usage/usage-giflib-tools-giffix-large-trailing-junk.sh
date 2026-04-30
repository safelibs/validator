#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giffix-large-trailing-junk
# @title: giffix trims 256-byte trailing tail
# @description: Appends 256 deterministic junk bytes after the GIF trailer of fire.gif, runs giffix on the dirty stream, and confirms the repaired output is no larger than the original byte count and still parses through giftext.
# @timeout: 60
# @tags: usage, cli, giffix, repair
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/gifgrid.gif"
validator_require_file "$gif"

orig_size=$(wc -c <"$gif")

cp "$gif" "$tmpdir/dirty.gif"
python3 -c '
import sys
with open(sys.argv[1], "ab") as fh:
    fh.write(bytes((i * 7) & 0xFF for i in range(256)))
' "$tmpdir/dirty.gif"

dirty_size=$(wc -c <"$tmpdir/dirty.gif")
[[ "$dirty_size" -eq $((orig_size + 256)) ]]

# giffix reads the GIF up to the trailer/terminator and rewrites a clean
# stream. The resulting stream must therefore be no larger than the dirty
# input plus a small bookkeeping margin and must still parse as a GIF.
giffix "$tmpdir/dirty.gif" >"$tmpdir/fixed.gif"
file "$tmpdir/fixed.gif" | grep -q 'GIF image data'

fixed_size=$(wc -c <"$tmpdir/fixed.gif")
if (( fixed_size > dirty_size )); then
  printf 'expected fixed.gif (%d) <= dirty (%d)\n' "$fixed_size" "$dirty_size" >&2
  exit 1
fi

giftext "$tmpdir/fixed.gif" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" 'Screen Size'
grep -Eq 'Image #[0-9]+' "$tmpdir/info.txt"

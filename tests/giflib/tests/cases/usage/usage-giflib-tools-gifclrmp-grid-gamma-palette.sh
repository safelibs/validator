#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gifclrmp-grid-gamma-palette
# @title: gifclrmp -g applies a gamma transform to the palette
# @description: Dumps the gifgrid.gif palette with gifclrmp -s as a baseline, applies a non-trivial gamma value with gifclrmp -g 2.2 to produce a transformed GIF, dumps that GIF's palette, and verifies the row count is preserved while at least one channel value in the palette has changed, demonstrating gifclrmp performed a real per-channel transformation rather than a no-op copy.
# @timeout: 60
# @tags: usage, cli, gifclrmp, palette
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/gifgrid.gif"
validator_require_file "$gif"

# Baseline palette dump.
gifclrmp -s "$gif" >"$tmpdir/before.txt"
before_rows=$(wc -l <"$tmpdir/before.txt")
(( before_rows >= 2 )) || {
  printf 'expected baseline palette to have rows, got %d\n' "$before_rows" >&2
  exit 1
}

# Apply a gamma transform to the palette and emit a new GIF.
gifclrmp -g 2.2 "$gif" >"$tmpdir/gamma.gif"
file "$tmpdir/gamma.gif" | grep -q 'GIF image data'

# Dump the post-gamma palette.
gifclrmp -s "$tmpdir/gamma.gif" >"$tmpdir/after.txt"
after_rows=$(wc -l <"$tmpdir/after.txt")

# Row count must be preserved.
if [[ "$before_rows" != "$after_rows" ]]; then
  printf 'palette row count drift: before=%s after=%s\n' "$before_rows" "$after_rows" >&2
  exit 1
fi

# At least one row must differ between baseline and post-gamma palette.
if cmp -s "$tmpdir/before.txt" "$tmpdir/after.txt"; then
  printf 'gifclrmp -g 2.2 produced an identical palette dump (no-op)\n' >&2
  exit 1
fi

# And the post-gamma file must remain decodable end-to-end.
giftext "$tmpdir/gamma.gif" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" 'Screen Size'
grep -Eq 'Image #[0-9]+' "$tmpdir/info.txt"

#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gifclrmp-grid-load-fire-palette
# @title: gifclrmp -l swaps the gifgrid palette with one dumped from fire
# @description: Dumps the fire.gif color map with gifclrmp -s, applies that palette to gifgrid.gif via gifclrmp -l, and confirms the resulting GIF reports a colormap whose first content row matches the fire palette row, exercising a cross-fixture palette transplant.
# @timeout: 60
# @tags: usage, cli, gifclrmp, colormap
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
target="$VALIDATOR_SAMPLE_ROOT/pic/gifgrid.gif"
validator_require_file "$src"
validator_require_file "$target"

# Capture the original gifgrid palette and the donor fire palette.
gifclrmp -s "$src" >"$tmpdir/fire-cmap.txt"
gifclrmp -s "$target" >"$tmpdir/grid-cmap-orig.txt"

# Both palettes must have at least 2 rows (header + entries).
(( $(wc -l <"$tmpdir/fire-cmap.txt") >= 2 ))
(( $(wc -l <"$tmpdir/grid-cmap-orig.txt") >= 2 ))

# Load the fire palette onto gifgrid; produce a new GIF.
gifclrmp -l "$tmpdir/fire-cmap.txt" "$target" >"$tmpdir/grid-fire.gif"
file "$tmpdir/grid-fire.gif" | grep -q 'GIF image data'

# Re-dump the recolored GIF's palette.
gifclrmp -s "$tmpdir/grid-fire.gif" >"$tmpdir/grid-cmap-after.txt"

# The transplanted palette must differ from the original gifgrid palette
# (donor and recipient have distinct colors), and a representative row from
# the donor must be present in the recipient's new palette dump.
if cmp -s "$tmpdir/grid-cmap-orig.txt" "$tmpdir/grid-cmap-after.txt"; then
  printf 'palette transplant did not change the gifgrid colormap\n' >&2
  exit 1
fi

donor_row=$(awk 'NR==2 {print $2, $3, $4}' "$tmpdir/fire-cmap.txt")
[[ -n "$donor_row" ]] || { printf 'could not extract donor row\n' >&2; exit 1; }
if ! awk -v r="$donor_row" 'NR>=2 { if ($2" "$3" "$4 == r) found=1 } END { exit found?0:1 }' \
      "$tmpdir/grid-cmap-after.txt"; then
  printf 'expected donor row %q to appear in transplanted palette\n' "$donor_row" >&2
  sed -n '1,5p' "$tmpdir/grid-cmap-after.txt" >&2
  exit 1
fi

#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gifclrmp-grid-reload-modified
# @title: gifclrmp -l reloads a modified palette
# @description: Dumps the gifgrid.gif color map with gifclrmp -s, edits one palette row to a known RGB triple, reloads that palette with gifclrmp -l, and confirms the reloaded GIF round-trips through gifclrmp -s yielding the modified row verbatim.
# @timeout: 60
# @tags: usage, cli, gifclrmp, colormap
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/gifgrid.gif"
validator_require_file "$gif"

gifclrmp -s "$gif" >"$tmpdir/cmap.txt"
orig_lines=$(wc -l <"$tmpdir/cmap.txt")
(( orig_lines >= 2 ))

# Replace the second palette row with a fixed sentinel triple.
python3 -c '
import sys
src, dst = sys.argv[1], sys.argv[2]
with open(src) as fh:
    lines = fh.readlines()
# Each row is "<index> <r> <g> <b>"; rewrite row 1.
parts = lines[1].split()
parts[1], parts[2], parts[3] = "11", "22", "33"
lines[1] = " ".join(parts) + "\n"
with open(dst, "w") as fh:
    fh.writelines(lines)
' "$tmpdir/cmap.txt" "$tmpdir/cmap-mod.txt"

gifclrmp -l "$tmpdir/cmap-mod.txt" "$gif" >"$tmpdir/modded.gif"
file "$tmpdir/modded.gif" | grep -q 'GIF image data'

gifclrmp -s "$tmpdir/modded.gif" >"$tmpdir/cmap2.txt"
[[ "$(wc -l <"$tmpdir/cmap2.txt")" -eq "$orig_lines" ]]

# Row 1 in the dumped map of the modified GIF must contain the sentinel triple.
sentinel=$(awk 'NR==2 {print $2, $3, $4}' "$tmpdir/cmap2.txt")
if [[ "$sentinel" != "11 22 33" ]]; then
  printf 'expected sentinel "11 22 33" in row 1, got %q\n' "$sentinel" >&2
  sed -n '1,4p' "$tmpdir/cmap2.txt" >&2
  exit 1
fi

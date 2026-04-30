#!/usr/bin/env bash
# @testcase: usage-bzdiff-identical-different-levels
# @title: bzdiff reports zero diff across all bzip2 levels
# @description: Compresses identical content at every bzip2 level from -1 through -9, then runs bzdiff between the level-1 archive and each other level, verifying every comparison reports no payload difference.
# @timeout: 300
# @tags: usage, bzdiff, levels
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzdiff-identical-different-levels"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Generate enough content that the encoder really uses different settings.
python3 -c "import sys
for i in range(4096):
    sys.stdout.write(f'bzdiff cross-level identity line {i % 31}\n')" >"$tmpdir/in.txt"

# Compress at every level -1..-9 to its own .bz2 file.
for level in 1 2 3 4 5 6 7 8 9; do
  bzip2 -"$level" -c "$tmpdir/in.txt" >"$tmpdir/level${level}.bz2"
done

# Levels -1 and -9 must produce distinct compressed bytes; otherwise the
# comparisons collapse into a trivial cmp.
if cmp -s "$tmpdir/level1.bz2" "$tmpdir/level9.bz2"; then
  printf 'level1 and level9 streams are byte-identical\n' >&2
  exit 1
fi

# bzdiff between level1 and each other level must exit 0 with no output.
for level in 2 3 4 5 6 7 8 9; do
  bzdiff "$tmpdir/level1.bz2" "$tmpdir/level${level}.bz2" \
    >"$tmpdir/out${level}" 2>"$tmpdir/err${level}"
  if [[ -s "$tmpdir/out${level}" ]]; then
    printf 'bzdiff level1 vs level%s emitted unexpected output\n' "$level" >&2
    sed -n '1,40p' "$tmpdir/out${level}" >&2
    exit 1
  fi
  if [[ -s "$tmpdir/err${level}" ]]; then
    printf 'bzdiff level1 vs level%s emitted unexpected stderr\n' "$level" >&2
    sed -n '1,40p' "$tmpdir/err${level}" >&2
    exit 1
  fi
done

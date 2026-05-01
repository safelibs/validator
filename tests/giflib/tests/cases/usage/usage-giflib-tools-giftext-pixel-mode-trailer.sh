#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giftext-pixel-mode-trailer
# @title: giftext -p ends with the GIF terminated normally trailer line
# @description: Runs giftext -p on fire.gif to dump pixel-level information and verifies the output's final non-empty line is the literal "GIF file terminated normally." sentinel that giftext writes only when the input parsed cleanly to EOF, anchoring the pixel-dump completion behavior.
# @timeout: 60
# @tags: usage, cli, giftext, pixels
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

giftext -p "$gif" >"$tmpdir/pixels.txt"

# Output should be substantial.
lines=$(wc -l <"$tmpdir/pixels.txt")
if (( lines < 50 )); then
  printf 'expected substantial pixel dump, got %s lines\n' "$lines" >&2
  exit 1
fi

# Last non-empty line must be the trailer.
last_nonblank=$(awk 'NF { line=$0 } END { print line }' "$tmpdir/pixels.txt")
if [[ "$last_nonblank" != "GIF file terminated normally." ]]; then
  printf 'expected trailer "GIF file terminated normally.", got %q\n' \
    "$last_nonblank" >&2
  tail -n 5 "$tmpdir/pixels.txt" >&2
  exit 1
fi

# Pixel mode should still emit at least one Image #N record.
if ! grep -qE '^Image #[0-9]+:' "$tmpdir/pixels.txt"; then
  printf 'pixel-mode output had no Image # records\n' >&2
  exit 1
fi

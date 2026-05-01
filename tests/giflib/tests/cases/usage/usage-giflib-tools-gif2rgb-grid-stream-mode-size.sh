#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gif2rgb-grid-stream-mode-size
# @title: gif2rgb -1 stream output for gifgrid matches width times height times three
# @description: Decodes gifgrid.gif with gif2rgb -1 into a single concatenated RGB byte stream, parses the screen width and height from giftext, and asserts the resulting file is exactly width*height*3 bytes long, validating the single-frame stream-mode pixel budget.
# @timeout: 60
# @tags: usage, cli, gif2rgb, stream
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/gifgrid.gif"
validator_require_file "$gif"

giftext "$gif" >"$tmpdir/text.txt"
read -r width height < <(sed -n 's/.*Screen Size - Width = \([0-9]*\), Height = \([0-9]*\)\..*/\1 \2/p' "$tmpdir/text.txt" | head -n1)
[[ -n "${width:-}" && -n "${height:-}" ]] || {
  printf 'failed to parse screen size from giftext\n' >&2
  cat "$tmpdir/text.txt" >&2
  exit 1
}

gif2rgb -1 -o "$tmpdir/grid.rgb" "$gif"

actual=$(stat -c '%s' "$tmpdir/grid.rgb")
expected=$(( width * height * 3 ))
[[ "$actual" == "$expected" ]] || {
  printf 'rgb byte size mismatch: expected %s (=%sx%sx3), got %s\n' \
    "$expected" "$width" "$height" "$actual" >&2
  exit 1
}

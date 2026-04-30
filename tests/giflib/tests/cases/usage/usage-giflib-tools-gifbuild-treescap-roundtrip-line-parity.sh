#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gifbuild-treescap-roundtrip-line-parity
# @title: gifbuild dump line count is identical before and after a roundtrip
# @description: Dumps treescap.gif with gifbuild -d, rebuilds the GIF from that dump by piping it back through gifbuild, dumps the rebuilt GIF a second time, and asserts the two textual descriptions have identical line counts and identical numbers of "image # N" headers and "terminator" markers, confirming that the dump-build-dump cycle is line-parity stable.
# @timeout: 60
# @tags: usage, cli, gifbuild, roundtrip
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

gifbuild -d "$gif" >"$tmpdir/first.txt"
first_lines=$(wc -l <"$tmpdir/first.txt")
(( first_lines > 10 )) || {
  printf 'expected gifbuild dump to have several lines, got %d\n' "$first_lines" >&2
  exit 1
}

# Rebuild the GIF from the dump, then dump it again.
gifbuild <"$tmpdir/first.txt" >"$tmpdir/rebuilt.gif"
file "$tmpdir/rebuilt.gif" | grep -q 'GIF image data'

gifbuild -d "$tmpdir/rebuilt.gif" >"$tmpdir/second.txt"
second_lines=$(wc -l <"$tmpdir/second.txt")

if [[ "$first_lines" != "$second_lines" ]]; then
  printf 'line count drift: first=%s second=%s\n' "$first_lines" "$second_lines" >&2
  diff "$tmpdir/first.txt" "$tmpdir/second.txt" >&2 || true
  exit 1
fi

# Image header and terminator parity must also match exactly.
first_images=$(grep -cE '^image # [0-9]+$' "$tmpdir/first.txt"  || true)
second_images=$(grep -cE '^image # [0-9]+$' "$tmpdir/second.txt" || true)
[[ "$first_images" == "$second_images" ]] || {
  printf 'image header drift: first=%s second=%s\n' "$first_images" "$second_images" >&2
  exit 1
}

first_end=$(grep -c '^end$' "$tmpdir/first.txt"  || true)
second_end=$(grep -c '^end$' "$tmpdir/second.txt" || true)
[[ "$first_end" == "$second_end" ]] || {
  printf 'end marker drift: first=%s second=%s\n' "$first_end" "$second_end" >&2
  exit 1
}
(( first_end >= 1 )) || {
  printf 'expected at least one end marker in dump\n' >&2
  exit 1
}

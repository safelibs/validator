#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gifbuild-fire-double-roundtrip
# @title: gifbuild fire dump build dump is byte-stable
# @description: Dumps the animated fire.gif with gifbuild -d, rebuilds the binary GIF, dumps it again, strips the source-filename comments, and verifies the two structural dumps are byte-identical and contain the expected screen width header.
# @timeout: 60
# @tags: usage, cli, gifbuild, roundtrip, animation
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

gifbuild -d "$gif" >"$tmpdir/dump1-raw.txt"
gifbuild "$tmpdir/dump1-raw.txt" >"$tmpdir/rebuilt.gif"
file "$tmpdir/rebuilt.gif" | grep -q 'GIF image data'
gifbuild -d "$tmpdir/rebuilt.gif" >"$tmpdir/dump2-raw.txt"

strip_filename_comments() {
  grep -v -E '^# GIF information from |^# End of .* dump$' "$1"
}
strip_filename_comments "$tmpdir/dump1-raw.txt" >"$tmpdir/dump1.txt"
strip_filename_comments "$tmpdir/dump2-raw.txt" >"$tmpdir/dump2.txt"

if ! diff -q "$tmpdir/dump1.txt" "$tmpdir/dump2.txt" >/dev/null; then
  printf 'gifbuild double-roundtrip dumps differ for fire.gif\n' >&2
  diff -u "$tmpdir/dump1.txt" "$tmpdir/dump2.txt" | sed -n '1,80p' >&2
  exit 1
fi

test "$(wc -c <"$tmpdir/dump1.txt")" -gt 0
grep -q '^screen width ' "$tmpdir/dump1.txt"

# fire.gif is animated; both dumps must contain at least two image # headers.
frames=$(grep -cE '^image # [0-9]+$' "$tmpdir/dump1.txt" || true)
(( frames > 1 )) || {
  printf 'expected animated fixture (>=2 frames), got %d\n' "$frames" >&2
  exit 1
}

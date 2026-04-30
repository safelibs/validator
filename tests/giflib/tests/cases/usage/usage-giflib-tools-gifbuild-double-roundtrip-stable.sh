#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gifbuild-double-roundtrip-stable
# @title: gifbuild dump build dump is byte-stable
# @description: Dumps a GIF with gifbuild -d, rebuilds the binary GIF, dumps it again, and verifies that the second textual dump is byte-identical to the first to confirm the gifbuild text format is a stable fixed point.
# @timeout: 60
# @tags: usage, cli, gifbuild, roundtrip
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/gifgrid.gif"
validator_require_file "$gif"

gifbuild -d "$gif" >"$tmpdir/dump1-raw.txt"
gifbuild "$tmpdir/dump1-raw.txt" >"$tmpdir/rebuilt.gif"
gifbuild -d "$tmpdir/rebuilt.gif" >"$tmpdir/dump2-raw.txt"

# gifbuild -d echoes the source filename in `# GIF information from <path>`
# and a matching `# End of <path> dump` comment. Strip those two lines so the
# comparison is on the structural dump only.
strip_filename_comments() {
  grep -v -E '^# GIF information from |^# End of .* dump$' "$1"
}
strip_filename_comments "$tmpdir/dump1-raw.txt" >"$tmpdir/dump1.txt"
strip_filename_comments "$tmpdir/dump2-raw.txt" >"$tmpdir/dump2.txt"

if ! diff -q "$tmpdir/dump1.txt" "$tmpdir/dump2.txt" >/dev/null; then
  printf 'gifbuild double-roundtrip dumps differ\n' >&2
  diff -u "$tmpdir/dump1.txt" "$tmpdir/dump2.txt" | sed -n '1,80p' >&2
  exit 1
fi

# Sanity: the dumps must be non-empty and contain real structural lines.
test "$(wc -c <"$tmpdir/dump1.txt")" -gt 0
grep -q '^screen width ' "$tmpdir/dump1.txt"

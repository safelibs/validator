#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-cli-quiet-no-banner
# @title: zstd CLI -q quiet suppresses summary banner
# @description: Compresses a payload twice, first with the default zstd CLI (which prints a per-file summary banner showing the compression ratio on stderr) and then with -q, and verifies that the quiet invocation produces empty stderr while still emitting an identical compressed frame that round-trips byte-for-byte.
# @timeout: 120
# @tags: usage, archive, zstd, cli, quiet
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/payload.bin"
python3 -c 'import sys
sys.stdout.buffer.write(b"quiet banner suppression payload\n" * 1024)' >"$src"
validator_require_file "$src"
src_sum=$(sha256sum "$src" | awk '{print $1}')

# Default invocation: stderr should contain the summary banner with the source
# filename and a percentage marker.
zstd --no-progress -o "$tmpdir/loud.zst" "$src" 2>"$tmpdir/loud.err"
validator_require_file "$tmpdir/loud.zst"
if ! grep -q '%' "$tmpdir/loud.err"; then
  printf 'baseline zstd run did not print the expected summary banner\n' >&2
  cat "$tmpdir/loud.err" >&2
  exit 1
fi

# Quiet invocation: stderr must be empty (no banner, no warnings).
zstd -q --no-progress -o "$tmpdir/quiet.zst" "$src" 2>"$tmpdir/quiet.err"
validator_require_file "$tmpdir/quiet.zst"
if [[ -s "$tmpdir/quiet.err" ]]; then
  printf 'zstd -q produced unexpected stderr output:\n' >&2
  cat "$tmpdir/quiet.err" >&2
  exit 1
fi

# Both frames must validate and decode to the original payload.
zstd -tq "$tmpdir/loud.zst" "$tmpdir/quiet.zst"
zstd -dq -c "$tmpdir/quiet.zst" >"$tmpdir/decoded.bin"
cmp "$src" "$tmpdir/decoded.bin"

dst_sum=$(sha256sum "$tmpdir/decoded.bin" | awk '{print $1}')
test "$src_sum" = "$dst_sum"

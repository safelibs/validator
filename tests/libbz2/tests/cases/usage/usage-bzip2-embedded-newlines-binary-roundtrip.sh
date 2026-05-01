#!/usr/bin/env bash
# @testcase: usage-bzip2-embedded-newlines-binary-roundtrip
# @title: bzip2 round-trips arbitrary binary with embedded newlines
# @description: Builds a payload mixing newline bytes, NUL bytes, and the full 0..255 byte range, round-trips it through bzip2/bunzip2, and verifies sha256 matches.
# @timeout: 180
# @tags: usage, bzip2, binary, newlines
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.bin" <<'PY'
import sys
path = sys.argv[1]
buf = bytearray()
# Repeat the full 0..255 range several times, sprinkled with embedded newlines.
for rep in range(64):
    buf.extend(bytes(range(256)))
    buf.extend(b"\n\n")
    buf.extend(b"line marker " + str(rep).encode() + b"\n")
    buf.extend(b"\x00\x00\x01\x02\x03\n")
with open(path, "wb") as f:
    f.write(buf)
PY

orig_size=$(wc -c <"$tmpdir/in.bin")
[[ "$orig_size" -gt 16000 ]] || {
  printf 'expected payload >16KiB, got %s\n' "$orig_size" >&2
  exit 1
}
orig_sha=$(sha256sum "$tmpdir/in.bin" | awk '{print $1}')

# Confirm payload actually contains both \n and \0.
nl_count=$(tr -cd '\n' <"$tmpdir/in.bin" | wc -c)
nul_count=$(tr -cd '\000' <"$tmpdir/in.bin" | wc -c)
[[ "$nl_count" -ge 64 ]] || { printf 'too few newlines: %s\n' "$nl_count" >&2; exit 1; }
[[ "$nul_count" -ge 64 ]] || { printf 'too few NULs: %s\n' "$nul_count" >&2; exit 1; }

bzip2 -c "$tmpdir/in.bin" >"$tmpdir/in.bin.bz2"
bzip2 -t "$tmpdir/in.bin.bz2"

bunzip2 -c "$tmpdir/in.bin.bz2" >"$tmpdir/round.bin"

new_size=$(wc -c <"$tmpdir/round.bin")
new_sha=$(sha256sum "$tmpdir/round.bin" | awk '{print $1}')
[[ "$new_size" -eq "$orig_size" ]] || {
  printf 'size mismatch: %s vs %s\n' "$orig_size" "$new_size" >&2
  exit 1
}
[[ "$new_sha" == "$orig_sha" ]] || {
  printf 'sha mismatch: %s vs %s\n' "$orig_sha" "$new_sha" >&2
  exit 1
}
cmp "$tmpdir/in.bin" "$tmpdir/round.bin"

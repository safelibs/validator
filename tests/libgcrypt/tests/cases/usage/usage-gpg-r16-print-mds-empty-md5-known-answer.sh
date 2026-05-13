#!/usr/bin/env bash
# @testcase: usage-gpg-r16-print-mds-empty-md5-known-answer
# @title: gpg --print-mds on empty input emits MD5 = d41d8cd98f00b204e9800998ecf8427e
# @description: Runs gpg --print-mds on a zero-byte file and asserts the MD5 line of the multi-digest listing equals the canonical empty-string MD5 d41d8cd98f00b204e9800998ecf8427e (case-insensitive hex match), exercising libgcrypt's MD5 implementation on the empty input KAT.
# @timeout: 60
# @tags: usage, gpg, print-mds, md5, kat
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

: >"$tmpdir/empty.bin"

gpg --batch --print-mds "$tmpdir/empty.bin" >"$tmpdir/out" 2>"$tmpdir/err"

# gpg --print-mds wraps long digests across multiple continuation lines.
# Capture from "MD5 =" up to (but not including) the next algorithm header
# (SHA/RMD), then strip all non-hex characters.
md5_hex=$(LC_ALL=C python3 - "$tmpdir/out" <<'PY'
import re, sys
data = open(sys.argv[1]).read()
m = re.search(r"MD5\s*=\s*([0-9A-Fa-f][0-9A-Fa-f\s]*?)(?=\n[^ \t]|\n\s*(?:SHA|RMD)\b)", data, re.S)
if not m:
    sys.exit("MD5 row not found")
print(re.sub(r"[^0-9A-Fa-f]", "", m.group(1)).lower())
PY
)
expected='d41d8cd98f00b204e9800998ecf8427e'
if [[ "$md5_hex" != "$expected" ]]; then
  printf 'expected MD5(empty)=%s, got %s\n' "$expected" "$md5_hex" >&2
  cat "$tmpdir/out" >&2
  exit 1
fi

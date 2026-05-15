#!/usr/bin/env bash
# @testcase: usage-gpg-r20-print-md-sha3-384-empty-vector
# @title: gpg --print-md SHA3-384 on empty input matches the published KAT
# @description: Pipes a zero-byte file to gpg --print-md SHA3-384 and asserts the captured digest equals the published SHA3-384("") known answer (0c63a75b...51e7f3d52e7afc62), exercising libgcrypt's SHA3-384 digest path on the empty-input boundary (a digest variant not covered by prior rounds).
# @timeout: 60
# @tags: usage, gpg, print-md, sha3-384, empty-vector, r20
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

: >"$tmpdir/empty.bin"
[[ "$(wc -c <"$tmpdir/empty.bin")" -eq 0 ]] || { echo 'fixture not empty' >&2; exit 1; }

gpg --print-md SHA3-384 "$tmpdir/empty.bin" >"$tmpdir/out" 2>"$tmpdir/err"

digest=$(LC_ALL=C sed -e 's/^[^:]*:[[:space:]]*//' "$tmpdir/out" \
  | LC_ALL=C tr -cd '0-9A-Fa-f' \
  | LC_ALL=C tr 'A-F' 'a-f')
digest=${digest:0:96}
expected='0c63a75b845e4f7d01107d852e4c2485c51a50aaaa94fc61995e71bbee983a2ac3713831264adb47fb6bd1e058d5f004'
if [[ "$digest" != "$expected" ]]; then
  printf 'expected SHA3-384(empty)=%s, got %s\n' "$expected" "$digest" >&2
  cat "$tmpdir/out" >&2
  exit 1
fi

#!/usr/bin/env bash
# @testcase: usage-gpg-r11-enarmor-dearmor-roundtrip
# @title: gpg --enarmor + --dearmor round-trip raw bytes byte-equal
# @description: Pipes 64 random bytes through --enarmor (which produces a "BEGIN PGP ARMORED FILE" block) and back through --dearmor, then verifies the recovered bytes match the original via sha256 equality.
# @timeout: 60
# @tags: usage, gpg, enarmor, dearmor
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

head -c 64 /dev/urandom >"$tmpdir/raw.bin"

gpg --batch --enarmor <"$tmpdir/raw.bin" >"$tmpdir/raw.armored" 2>/dev/null

grep -q '^-----BEGIN PGP ARMORED FILE-----' "$tmpdir/raw.armored"
grep -q '^-----END PGP ARMORED FILE-----'   "$tmpdir/raw.armored"

gpg --batch --dearmor <"$tmpdir/raw.armored" >"$tmpdir/raw.recovered" 2>/dev/null

orig=$(sha256sum <"$tmpdir/raw.bin"       | awk '{print $1}')
back=$(sha256sum <"$tmpdir/raw.recovered" | awk '{print $1}')
[[ "$orig" == "$back" ]] || {
  printf 'roundtrip mismatch: orig=%s back=%s\n' "$orig" "$back" >&2
  exit 1
}

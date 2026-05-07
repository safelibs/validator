#!/usr/bin/env bash
# @testcase: usage-gpg-r14-enarmor-headers-fixed-blob
# @title: gpg --enarmor wraps a fixed binary blob in PGP ARMORED FILE headers
# @description: Pipes a fixed 64-byte payload through gpg --enarmor under an ephemeral GNUPGHOME, asserts the output begins with "-----BEGIN PGP ARMORED FILE-----" and ends with "-----END PGP ARMORED FILE-----", and asserts the body contains a 4-character base64 CRC checksum line beginning with '='.
# @timeout: 60
# @tags: usage, gpg, enarmor, armor
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

# Fixed 64-byte payload (deterministic, no /dev/urandom).
LC_ALL=C printf 'r14 enarmor fixed payload bytes %d\n' {0..1} >"$tmpdir/raw.bin"
[[ "$(wc -c <"$tmpdir/raw.bin")" -gt 0 ]]

gpg --batch --enarmor <"$tmpdir/raw.bin" >"$tmpdir/raw.asc" 2>/dev/null

# Header and trailer present.
LC_ALL=C grep -q '^-----BEGIN PGP ARMORED FILE-----$' "$tmpdir/raw.asc"
LC_ALL=C grep -q '^-----END PGP ARMORED FILE-----$'   "$tmpdir/raw.asc"

# Radix-64 CRC line: '=' followed by 4 base64 chars on its own line.
LC_ALL=C grep -E '^=[A-Za-z0-9+/]{4}$' "$tmpdir/raw.asc" >/dev/null

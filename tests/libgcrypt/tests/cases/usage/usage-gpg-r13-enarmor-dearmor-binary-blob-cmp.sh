#!/usr/bin/env bash
# @testcase: usage-gpg-r13-enarmor-dearmor-binary-blob-cmp
# @title: gpg --enarmor / --dearmor round-trip recovers a binary blob byte-for-byte
# @description: Generates 256 random binary bytes, pipes them through gpg --enarmor to produce an ASCII PGP ARMORED FILE block, asserts the begin and end armor headers are present, then runs gpg --dearmor and asserts the recovered bytes are byte-identical to the original via cmp.
# @timeout: 60
# @tags: usage, gpg, enarmor, dearmor, armor
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

head -c 256 /dev/urandom >"$tmpdir/raw.bin"
[[ "$(wc -c <"$tmpdir/raw.bin")" -eq 256 ]]

gpg --batch --enarmor <"$tmpdir/raw.bin" >"$tmpdir/raw.asc" 2>/dev/null

grep -q '^-----BEGIN PGP ARMORED FILE-----' "$tmpdir/raw.asc"
grep -q '^-----END PGP ARMORED FILE-----'   "$tmpdir/raw.asc"

gpg --batch --dearmor <"$tmpdir/raw.asc" >"$tmpdir/recovered.bin" 2>/dev/null

cmp "$tmpdir/raw.bin" "$tmpdir/recovered.bin"

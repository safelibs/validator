#!/usr/bin/env bash
# @testcase: usage-gpg-enarmor-roundtrip-sha256
# @title: gpg enarmor dearmor sha256 roundtrip
# @description: Encodes random binary content with gpg --enarmor, decodes it with --dearmor, and confirms the sha256 digest matches the original.
# @timeout: 180
# @tags: usage, gpg, armor
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-enarmor-roundtrip-sha256"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

# Use a deterministic but non-text byte stream so that any corruption,
# truncation, or accidental newline conversion would shift the sha256.
head -c 4096 /dev/urandom >"$tmpdir/plain.bin"
plain_sha=$(sha256sum "$tmpdir/plain.bin" | awk '{print $1}')

gpg --enarmor <"$tmpdir/plain.bin" >"$tmpdir/plain.asc"
head -n 1 "$tmpdir/plain.asc" >"$tmpdir/asc-head"
validator_assert_contains "$tmpdir/asc-head" '-----BEGIN PGP ARMORED FILE-----'

gpg --dearmor <"$tmpdir/plain.asc" >"$tmpdir/plain.out"
out_sha=$(sha256sum "$tmpdir/plain.out" | awk '{print $1}')
test "$plain_sha" = "$out_sha"
cmp -s "$tmpdir/plain.bin" "$tmpdir/plain.out"

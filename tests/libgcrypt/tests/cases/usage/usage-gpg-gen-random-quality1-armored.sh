#!/usr/bin/env bash
# @testcase: usage-gpg-gen-random-quality1-armored
# @title: gpg gen-random quality 1 armored
# @description: Requests 16 random bytes from gpg --gen-random with quality level 1 and --armor, decoding the base64 payload back to exactly 16 bytes.
# @timeout: 180
# @tags: usage, gpg, crypto, random
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-gen-random-quality1-armored"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg --armor --gen-random 1 16 >"$tmpdir/random.b64"
test -s "$tmpdir/random.b64"
# Base64 decoding the armored payload should produce exactly 16 bytes.
base64 -d <"$tmpdir/random.b64" >"$tmpdir/random.bin"
test "$(wc -c <"$tmpdir/random.bin")" -eq 16

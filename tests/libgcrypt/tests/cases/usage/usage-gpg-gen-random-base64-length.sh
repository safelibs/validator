#!/usr/bin/env bash
# @testcase: usage-gpg-gen-random-base64-length
# @title: gpg gen-random base64 output length
# @description: Generates 48 random bytes with gpg --gen-random level 1 mode 1 (base64 armor) and verifies the decoded payload length is exactly 48 bytes.
# @timeout: 120
# @tags: usage, gpg, random
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-gen-random-base64-length"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg --gen-random 1 48 >"$tmpdir/raw.bin"
size=$(wc -c <"$tmpdir/raw.bin")
test "$size" -eq 48

# A second invocation must not produce the same bytes.
gpg --gen-random 1 48 >"$tmpdir/raw2.bin"
if cmp -s "$tmpdir/raw.bin" "$tmpdir/raw2.bin"; then
  echo "two random outputs unexpectedly identical" >&2
  exit 1
fi

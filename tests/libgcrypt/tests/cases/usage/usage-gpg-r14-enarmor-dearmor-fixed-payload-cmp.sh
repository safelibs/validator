#!/usr/bin/env bash
# @testcase: usage-gpg-r14-enarmor-dearmor-fixed-payload-cmp
# @title: gpg --dearmor recovers a fixed binary payload from an enarmored block
# @description: Writes a fixed 128-byte payload, runs gpg --enarmor and then gpg --dearmor under an ephemeral GNUPGHOME, and asserts the recovered bytes are byte-identical to the original via cmp — a deterministic round-trip distinct from the random-blob enarmor variant.
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

# Deterministic 128-byte payload of low+high-byte mix. perl is in the
# libgcrypt validator container; python3 is not.
LC_ALL=C perl -e 'for ($i = 0; $i < 128; $i++) { print chr(($i * 7 + 3) & 0xff); }' >"$tmpdir/raw.bin"
[[ "$(wc -c <"$tmpdir/raw.bin")" -eq 128 ]]

gpg --batch --enarmor <"$tmpdir/raw.bin" >"$tmpdir/raw.asc" 2>/dev/null
gpg --batch --dearmor <"$tmpdir/raw.asc" >"$tmpdir/recovered.bin" 2>/dev/null

cmp "$tmpdir/raw.bin" "$tmpdir/recovered.bin"

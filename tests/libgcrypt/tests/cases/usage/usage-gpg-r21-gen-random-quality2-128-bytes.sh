#!/usr/bin/env bash
# @testcase: usage-gpg-r21-gen-random-quality2-128-bytes
# @title: gpg --gen-random 2 128 emits exactly 128 bytes of strong-quality randomness
# @description: Runs gpg --gen-random 2 128 to request 128 bytes from libgcrypt's strong-quality RNG (level 2) under an ephemeral GNUPGHOME, asserts the output is exactly 128 bytes, and that the bytes are not all identical (a trivial RNG sanity check) - locking in libgcrypt's GCRY_VERY_STRONG_RANDOM byte count at a 128-byte request distinct from prior 4/8/64-byte quality-2 tests.
# @timeout: 60
# @tags: usage, gpg, gen-random, quality2, r21
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg --gen-random 2 128 >"$tmpdir/r.bin" 2>"$tmpdir/err"
size=$(wc -c <"$tmpdir/r.bin")
[[ "$size" -eq 128 ]] || { printf 'expected 128 bytes, got %s\n' "$size" >&2; exit 1; }

# Ensure not all bytes are identical (extremely unlikely from a real RNG).
unique=$(LC_ALL=C od -An -tu1 -v "$tmpdir/r.bin" | LC_ALL=C tr -s ' \n' '\n' \
    | LC_ALL=C grep -v '^$' | LC_ALL=C sort -u | LC_ALL=C wc -l)
[[ "$unique" -ge 2 ]] || { echo 'gen-random output is constant; not a random byte stream' >&2; exit 1; }

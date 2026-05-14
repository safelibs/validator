#!/usr/bin/env bash
# @testcase: usage-gpg-r18-gen-random-quality2-sixty-four-bytes
# @title: gpg --gen-random 2 64 emits exactly 64 bytes and is not all-zeros
# @description: Runs gpg --gen-random 2 64 (libgcrypt quality level 2 — long-term) under an ephemeral GNUPGHOME and asserts the output is exactly 64 raw bytes and contains at least one non-zero byte (rejecting the degenerate all-zero output), exercising the long-term-quality RNG at a 64-byte payload distinct from existing 8/16/32-byte coverage.
# @timeout: 90
# @tags: usage, gpg, gen-random, quality2, sixty-four, r18
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg --gen-random 2 64 >"$tmpdir/r.bin" 2>/dev/null
sz=$(wc -c <"$tmpdir/r.bin")
if [[ "$sz" -ne 64 ]]; then
  printf 'expected 64-byte output, got %s\n' "$sz" >&2
  exit 1
fi
# Ensure non-zero: count of nonzero bytes via tr / wc
nonzero=$(LC_ALL=C tr -d '\000' <"$tmpdir/r.bin" | wc -c)
if [[ "$nonzero" -eq 0 ]]; then
  echo 'gen-random level 2 produced all-zero bytes' >&2
  exit 1
fi

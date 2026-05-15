#!/usr/bin/env bash
# @testcase: usage-gpg-r19-gen-random-32-bytes-distinct
# @title: gpg --gen-random 1 32 produces 32 raw bytes that differ between two invocations
# @description: Invokes gpg --gen-random 1 32 twice (quality level 1, 32 bytes each), asserts each output is exactly 32 bytes, and asserts the two outputs are not byte-identical (libgcrypt's quality-1 generator must not return a fixed payload), exercising the random-number generator output sizing and non-degeneracy through gpg.
# @timeout: 60
# @tags: usage, gpg, gen-random, length, distinct, r19
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg --gen-random 1 32 >"$tmpdir/a.bin" 2>"$tmpdir/a.err"
gpg --gen-random 1 32 >"$tmpdir/b.bin" 2>"$tmpdir/b.err"

a_size=$(wc -c <"$tmpdir/a.bin")
b_size=$(wc -c <"$tmpdir/b.bin")
if [[ "$a_size" -ne 32 || "$b_size" -ne 32 ]]; then
  printf 'expected 32 bytes per invocation, got %s and %s\n' "$a_size" "$b_size" >&2
  exit 1
fi
if cmp -s "$tmpdir/a.bin" "$tmpdir/b.bin"; then
  echo 'two --gen-random invocations returned byte-identical output' >&2
  exit 1
fi

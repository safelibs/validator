#!/usr/bin/env bash
# @testcase: usage-gpg-r13-gen-random-byte-count-distinct
# @title: gpg --gen-random 0 emits the requested byte count and produces distinct outputs across runs
# @description: Runs gpg --gen-random 0 16 twice into separate files under an ephemeral GNUPGHOME, asserts each file is exactly 16 bytes (the requested length), and asserts the two outputs differ byte-for-byte (random level 0 must vary between calls).
# @timeout: 60
# @tags: usage, gpg, gen-random
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg --gen-random 0 16 >"$tmpdir/r1.bin" 2>/dev/null
gpg --gen-random 0 16 >"$tmpdir/r2.bin" 2>/dev/null

[[ "$(wc -c <"$tmpdir/r1.bin")" -eq 16 ]]
[[ "$(wc -c <"$tmpdir/r2.bin")" -eq 16 ]]

if cmp -s "$tmpdir/r1.bin" "$tmpdir/r2.bin"; then
  echo 'two gen-random invocations produced identical bytes' >&2
  exit 1
fi

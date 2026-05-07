#!/usr/bin/env bash
# @testcase: usage-gpg-r14-gen-random-level2-eight-bytes
# @title: gpg --gen-random level 2 emits exactly the requested byte count
# @description: Runs gpg --gen-random 2 8 (quality level 2 — strong RNG) under an ephemeral GNUPGHOME, redirects 8 raw bytes to a file, and asserts the output is exactly 8 bytes and that two independent calls produce different byte sequences.
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

gpg --gen-random 2 8 >"$tmpdir/r1.bin" 2>/dev/null
gpg --gen-random 2 8 >"$tmpdir/r2.bin" 2>/dev/null

[[ "$(wc -c <"$tmpdir/r1.bin")" -eq 8 ]]
[[ "$(wc -c <"$tmpdir/r2.bin")" -eq 8 ]]

if cmp -s "$tmpdir/r1.bin" "$tmpdir/r2.bin"; then
  echo 'two level-2 gen-random invocations produced identical bytes' >&2
  exit 1
fi

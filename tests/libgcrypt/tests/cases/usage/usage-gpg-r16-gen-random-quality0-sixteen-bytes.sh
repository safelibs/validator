#!/usr/bin/env bash
# @testcase: usage-gpg-r16-gen-random-quality0-sixteen-bytes
# @title: gpg --gen-random 0 16 emits exactly 16 bytes from the weak-quality RNG
# @description: Runs gpg --gen-random 0 16 (libgcrypt quality level 0 — weak) under an ephemeral GNUPGHOME and asserts the output is exactly 16 raw bytes and two independent calls produce different sequences, exercising the libgcrypt RNG at the low-quality level.
# @timeout: 60
# @tags: usage, gpg, gen-random, quality0
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg --gen-random 0 16 >"$tmpdir/a.bin" 2>/dev/null
gpg --gen-random 0 16 >"$tmpdir/b.bin" 2>/dev/null

[[ "$(wc -c <"$tmpdir/a.bin")" -eq 16 ]] || { echo 'a.bin not 16 bytes' >&2; exit 1; }
[[ "$(wc -c <"$tmpdir/b.bin")" -eq 16 ]] || { echo 'b.bin not 16 bytes' >&2; exit 1; }

if cmp -s "$tmpdir/a.bin" "$tmpdir/b.bin"; then
  echo 'two level-0 gen-random invocations produced identical bytes' >&2
  exit 1
fi

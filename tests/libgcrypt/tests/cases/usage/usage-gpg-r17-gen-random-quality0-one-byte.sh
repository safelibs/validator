#!/usr/bin/env bash
# @testcase: usage-gpg-r17-gen-random-quality0-one-byte
# @title: gpg --gen-random 0 1 emits exactly 1 byte
# @description: Runs gpg --gen-random 0 1 (libgcrypt quality level 0 — weak) under an ephemeral GNUPGHOME and asserts the captured output is exactly 1 byte long, exercising the smallest non-zero RNG request.
# @timeout: 60
# @tags: usage, gpg, gen-random, one-byte
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg --gen-random 0 1 >"$tmpdir/a.bin" 2>/dev/null
sz=$(wc -c <"$tmpdir/a.bin")
if [[ "$sz" -ne 1 ]]; then
  printf 'expected 1 byte, got %s\n' "$sz" >&2
  exit 1
fi

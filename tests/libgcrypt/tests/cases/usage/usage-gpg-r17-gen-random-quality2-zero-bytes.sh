#!/usr/bin/env bash
# @testcase: usage-gpg-r17-gen-random-quality2-zero-bytes
# @title: gpg --gen-random 2 0 produces empty output and exits zero
# @description: Runs gpg --gen-random 2 0 (quality level 2 — very strong; zero bytes requested) under an ephemeral GNUPGHOME and asserts the captured output is exactly 0 bytes and the exit status is zero, exercising the RNG with a zero-length request at the highest quality level.
# @timeout: 60
# @tags: usage, gpg, gen-random, zero-bytes
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

set +e
gpg --gen-random 2 0 >"$tmpdir/a.bin" 2>"$tmpdir/err"
rc=$?
set -e
if [[ $rc -ne 0 ]]; then
  printf 'expected exit 0, got %d\n' "$rc" >&2
  cat "$tmpdir/err" >&2
  exit 1
fi
sz=$(wc -c <"$tmpdir/a.bin")
if [[ "$sz" -ne 0 ]]; then
  printf 'expected 0 bytes, got %s\n' "$sz" >&2
  exit 1
fi

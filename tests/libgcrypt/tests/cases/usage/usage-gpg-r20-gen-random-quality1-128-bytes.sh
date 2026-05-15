#!/usr/bin/env bash
# @testcase: usage-gpg-r20-gen-random-quality1-128-bytes
# @title: gpg --gen-random 1 128 emits exactly 128 raw bytes
# @description: Calls gpg --gen-random 1 128 and asserts the captured output is exactly 128 bytes in length - locking in libgcrypt's random byte generator at quality level 1 for a length distinct from earlier rounds.
# @timeout: 60
# @tags: usage, gpg, gen-random, quality1, r20
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg --gen-random 1 128 >"$tmpdir/r.bin" 2>"$tmpdir/err"
n=$(wc -c <"$tmpdir/r.bin")
[[ "$n" -eq 128 ]] || {
    printf 'expected 128 bytes, got %s\n' "$n" >&2
    exit 1
}

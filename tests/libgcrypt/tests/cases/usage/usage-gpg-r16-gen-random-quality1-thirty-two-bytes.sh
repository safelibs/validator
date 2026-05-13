#!/usr/bin/env bash
# @testcase: usage-gpg-r16-gen-random-quality1-thirty-two-bytes
# @title: gpg --gen-random 1 32 emits 32 non-all-zero bytes from the medium-quality RNG
# @description: Runs gpg --gen-random 1 32 under an ephemeral GNUPGHOME and asserts the output is exactly 32 raw bytes and not the all-zero buffer, exercising libgcrypt's medium-quality (level 1) RNG path through gpg.
# @timeout: 60
# @tags: usage, gpg, gen-random, quality1
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg --gen-random 1 32 >"$tmpdir/r.bin" 2>/dev/null
[[ "$(wc -c <"$tmpdir/r.bin")" -eq 32 ]] || { echo 'r.bin not 32 bytes' >&2; exit 1; }

# 32 zero bytes is astronomically unlikely; reject if so.
LC_ALL=C perl -e 'undef $/; my $b = <>; exit 0 if $b =~ /[^\x00]/; exit 1;' <"$tmpdir/r.bin" || {
  echo 'gen-random produced all-zero buffer' >&2
  exit 1
}

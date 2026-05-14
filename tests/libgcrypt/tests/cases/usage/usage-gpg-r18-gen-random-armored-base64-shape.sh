#!/usr/bin/env bash
# @testcase: usage-gpg-r18-gen-random-armored-base64-shape
# @title: gpg --gen-random --armor 0 24 emits base64-shaped output of expected length
# @description: Runs gpg --gen-random --armor 0 24 under an ephemeral GNUPGHOME and asserts the output is a single base64 line consisting only of A-Z, a-z, 0-9, +, /, = and is exactly 32 chars long (24 bytes encodes to 32 base64 chars, no padding needed since 24%3==0), exercising the armor-encoded random output path.
# @timeout: 60
# @tags: usage, gpg, gen-random, armor, base64, r18
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg --gen-random --armor 0 24 >"$tmpdir/out" 2>/dev/null
content=$(LC_ALL=C tr -d '\n' <"$tmpdir/out")
if [[ "${#content}" -ne 32 ]]; then
  printf 'expected 32 base64 chars for 24 bytes, got %s\n' "${#content}" >&2
  cat "$tmpdir/out" >&2
  exit 1
fi
if ! LC_ALL=C printf '%s' "$content" | grep -Eq '^[A-Za-z0-9+/=]+$'; then
  printf 'expected base64-alphabet only, got: %s\n' "$content" >&2
  exit 1
fi

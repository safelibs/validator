#!/usr/bin/env bash
# @testcase: usage-gpg-print-md-ripemd160-kat-abc
# @title: gpg print-md RIPEMD160 KAT for "abc"
# @description: Computes the RIPEMD160 digest of the literal byte string "abc" through gpg --print-md and asserts the published Dobbertin/Bosselaers/Preneel known-answer value.
# @timeout: 120
# @tags: usage, gpg, digest, kat
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-print-md-ripemd160-kat-abc"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg_batch=(gpg --batch --yes --pinentry-mode loopback)

# Published RIPEMD-160 reference vector for "abc".
expected="8EB208F7E05D987A9B044A8E98C6B087F15A0BFC"

printf 'abc' >"$tmpdir/abc"
"${gpg_batch[@]}" --print-md RIPEMD160 "$tmpdir/abc" >"$tmpdir/raw"

# Strip the "<path>:" prefix and any whitespace, leaving a contiguous hex run.
hex=$(awk -F: 'NR==1 {sub(/^ +/, "", $2); print $2; next} {print}' "$tmpdir/raw" \
  | tr -d ' \t\n')
printf '%s' "$hex" | grep -qE '^[0-9A-F]{40}$' || {
  printf 'ripemd160 output is not 40 hex chars: %s\n' "$hex" >&2
  exit 1
}

if [[ "$hex" != "$expected" ]]; then
  printf 'ripemd160 KAT mismatch:\n  got:      %s\n  expected: %s\n' "$hex" "$expected" >&2
  exit 1
fi

#!/usr/bin/env bash
# @testcase: usage-gpg-max-cert-depth-verify
# @title: gpg --max-cert-depth accepted on verify
# @description: Confirms gpg accepts an explicit --max-cert-depth value (a numeric trust-model knob) on the command line during signature verification and still produces a Good signature for an ed25519 detached signature.
# @timeout: 180
# @tags: usage, gpg, verify, trust
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-max-cert-depth-verify"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
uid='Validator CertDepth <validator-certdepth@example.invalid>'

"${gpg_batch[@]}" --passphrase '' \
  --quick-generate-key "$uid" ed25519 sign 1d >/dev/null 2>&1

printf 'max-cert-depth payload\n' >"$tmpdir/plain.txt"
"${gpg_batch[@]}" --local-user "$uid" \
  --detach-sign -o "$tmpdir/plain.sig" "$tmpdir/plain.txt"

# Verify with an explicit --max-cert-depth; the option must be parsed without
# error and the signature must still verify cleanly.
gpg --batch --max-cert-depth 5 \
  --verify "$tmpdir/plain.sig" "$tmpdir/plain.txt" \
  >"$tmpdir/verify.out" 2>"$tmpdir/verify.err"

validator_assert_contains "$tmpdir/verify.err" 'Good signature'
validator_assert_contains "$tmpdir/verify.err" "$uid"

# A typo on the option must still be rejected, confirming the flag is the
# parser path that succeeded above and not silently ignored.
if gpg --batch --max-cert-depthX 5 \
     --verify "$tmpdir/plain.sig" "$tmpdir/plain.txt" \
     >/dev/null 2>"$tmpdir/typo.err"; then
  printf 'gpg accepted bogus --max-cert-depthX flag\n' >&2
  cat "$tmpdir/typo.err" >&2
  exit 1
fi

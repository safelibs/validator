#!/usr/bin/env bash
# @testcase: usage-gpg-passwd-dry-run
# @title: gpg --passwd --dry-run validates current passphrase
# @description: Generates a key with a known passphrase, runs --passwd --dry-run with the correct passphrase (must succeed), then runs --passwd --dry-run with the wrong passphrase (must fail with Bad passphrase), confirming libgcrypt-backed S2K verification is wired through.
# @timeout: 240
# @tags: usage, gpg, crypto
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-passwd-dry-run"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"
uid='Validator Passwd <validator-passwd@example.invalid>'
correct_pass='validator-correct-passphrase'
wrong_pass='validator-wrong-passphrase'

gpg --batch --yes --pinentry-mode loopback --passphrase "$correct_pass" \
  --quick-generate-key "$uid" default default 1d >/dev/null 2>&1

# Correct passphrase: --passwd --dry-run must succeed.
if ! gpg --batch --yes --dry-run --pinentry-mode loopback --passphrase "$correct_pass" \
    --passwd "$uid" >"$tmpdir/ok.out" 2>"$tmpdir/ok.err"; then
  printf '--passwd --dry-run with correct passphrase failed\n' >&2
  cat "$tmpdir/ok.err" >&2
  exit 1
fi

# Wrong passphrase: must fail and surface "Bad passphrase".
if gpg --batch --yes --dry-run --pinentry-mode loopback --passphrase "$wrong_pass" \
    --passwd "$uid" >"$tmpdir/bad.out" 2>"$tmpdir/bad.err"; then
  printf '--passwd --dry-run with wrong passphrase unexpectedly succeeded\n' >&2
  cat "$tmpdir/bad.err" >&2
  exit 1
fi
validator_assert_contains "$tmpdir/bad.err" 'Bad passphrase'

#!/usr/bin/env bash
# @testcase: usage-gpg-always-trust-untrusted-recipient
# @title: gpg always-trust unblocks untrusted recipient
# @description: Imports a foreign public key into a fresh keyring, confirms encryption fails with the default trust model, then succeeds once --always-trust (--trust-model always) is supplied.
# @timeout: 240
# @tags: usage, gpg, encryption, trust
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-always-trust-untrusted-recipient"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Two completely separate GNUPGHOMEs: one to generate+export the recipient key,
# one to receive it as a foreign (untrusted) key.
producer_home="$tmpdir/producer"
consumer_home="$tmpdir/consumer"
mkdir -p "$producer_home" "$consumer_home"
chmod 700 "$producer_home" "$consumer_home"

gpg_batch_producer=(gpg --homedir "$producer_home" --batch --yes --pinentry-mode loopback)
gpg_batch_consumer=(gpg --homedir "$consumer_home" --batch --yes --pinentry-mode loopback)

uid='Validator Untrusted <validator-untrusted@example.invalid>'

"${gpg_batch_producer[@]}" --passphrase '' --quick-generate-key "$uid" rsa2048 encrypt 1d >/dev/null 2>&1
"${gpg_batch_producer[@]}" --armor --export "$uid" >"$tmpdir/recipient.asc"
validator_assert_contains "$tmpdir/recipient.asc" 'BEGIN PGP PUBLIC KEY BLOCK'

"${gpg_batch_consumer[@]}" --import "$tmpdir/recipient.asc" >"$tmpdir/import.out" 2>&1
validator_assert_contains "$tmpdir/import.out" 'imported'

printf 'always-trust payload\n' >"$tmpdir/plain.txt"

# Default trust model: must refuse to encrypt to an unassured key in batch mode.
set +e
"${gpg_batch_consumer[@]}" --encrypt -r "$uid" -o "$tmpdir/fail.gpg" "$tmpdir/plain.txt" >"$tmpdir/fail.out" 2>&1
default_status=$?
set -e
test "$default_status" -ne 0
test ! -s "$tmpdir/fail.gpg" 2>/dev/null || test ! -e "$tmpdir/fail.gpg"
validator_assert_contains "$tmpdir/fail.out" 'no assurance'

# --always-trust must override the trust check and produce a real ciphertext.
"${gpg_batch_consumer[@]}" --always-trust --encrypt -r "$uid" -o "$tmpdir/ok.gpg" "$tmpdir/plain.txt"
test -s "$tmpdir/ok.gpg"

# Round-trip: producer should be able to decrypt what we just encrypted.
"${gpg_batch_producer[@]}" --decrypt -o "$tmpdir/ok.out" "$tmpdir/ok.gpg" >/dev/null 2>&1
validator_assert_contains "$tmpdir/ok.out" 'always-trust payload'

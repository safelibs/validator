#!/usr/bin/env bash
# @testcase: usage-gpg-quick-set-expire
# @title: gpg --quick-set-expire updates key expiration
# @description: Generates a primary key with a 1d expiration, calls --quick-set-expire to extend it to 2y, and verifies --list-keys reflects the new expiration date and not the original.
# @timeout: 240
# @tags: usage, gpg, key-management
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-quick-set-expire"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"
export GNUPGHOME

gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
uid='Expire User <expire@example.invalid>'

"${gpg_batch[@]}" --passphrase '' --quick-generate-key "$uid" ed25519 sign 1d >/dev/null 2>&1

# Capture the primary fingerprint via --with-colons.
fpr=$(gpg --list-keys --with-colons "$uid" | awk -F: '$1=="fpr"{print $10; exit}')
[[ -n "$fpr" ]] || { echo "no fingerprint extracted" >&2; exit 1; }

# Snapshot the original expiration epoch from colon listing.
orig_expire=$(gpg --list-keys --with-colons "$fpr" | awk -F: '$1=="pub"{print $7; exit}')
[[ -n "$orig_expire" ]] || { echo "no original expire epoch" >&2; exit 1; }

"${gpg_batch[@]}" --passphrase '' --quick-set-expire "$fpr" 2y

new_expire=$(gpg --list-keys --with-colons "$fpr" | awk -F: '$1=="pub"{print $7; exit}')
[[ -n "$new_expire" ]] || { echo "no new expire epoch" >&2; exit 1; }
[[ "$new_expire" != "$orig_expire" ]] || { echo "expiration unchanged: $new_expire" >&2; exit 1; }
[[ "$new_expire" -gt "$orig_expire" ]] || { echo "expiration not extended: $orig_expire -> $new_expire" >&2; exit 1; }

# Human-readable listing should also show the updated [expires: ...] tag.
gpg --list-keys "$fpr" >"$tmpdir/keys.txt"
validator_assert_contains "$tmpdir/keys.txt" 'expires:'

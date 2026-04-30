#!/usr/bin/env bash
# @testcase: usage-gpg-multifile-decrypt
# @title: gpg --multifile --decrypt of multiple armored files
# @description: Generates a recipient key, encrypts two payloads to separate armored files, and decrypts both in a single gpg --multifile --decrypt invocation, verifying each plaintext output file.
# @timeout: 180
# @tags: usage, gpg, encryption, multifile
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-multifile-decrypt"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"
export GNUPGHOME

gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
uid='Multifile User <multifile@example.invalid>'

"${gpg_batch[@]}" --passphrase '' --quick-generate-key "$uid" default default 1d >/dev/null 2>&1

work="$tmpdir/work"
mkdir -p "$work"
printf 'alpha payload\n' >"$work/alpha.txt"
printf 'beta payload\n'  >"$work/beta.txt"

"${gpg_batch[@]}" --trust-model always --armor --encrypt -r "$uid" -o "$work/alpha.txt.asc" "$work/alpha.txt"
"${gpg_batch[@]}" --trust-model always --armor --encrypt -r "$uid" -o "$work/beta.txt.asc"  "$work/beta.txt"

# Remove plaintext so --multifile --decrypt must regenerate alpha.txt and beta.txt.
rm -f "$work/alpha.txt" "$work/beta.txt"

"${gpg_batch[@]}" --multifile --decrypt "$work/alpha.txt.asc" "$work/beta.txt.asc"

validator_require_file "$work/alpha.txt"
validator_require_file "$work/beta.txt"
validator_assert_contains "$work/alpha.txt" 'alpha payload'
validator_assert_contains "$work/beta.txt"  'beta payload'

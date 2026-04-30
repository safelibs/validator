#!/usr/bin/env bash
# @testcase: usage-gpg-quick-add-uid
# @title: gpg --quick-add-uid attaches a new user id
# @description: Generates a key, attaches a second user id with --quick-add-uid, and verifies that --list-keys reports both user ids on the same primary key.
# @timeout: 180
# @tags: usage, gpg, keyring
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-quick-add-uid"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"
gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
primary_uid='Validator AddUid <validator-add-uid@example.invalid>'
extra_uid='Validator AddUid Extra <validator-add-uid-extra@example.invalid>'

"${gpg_batch[@]}" --passphrase '' --quick-generate-key "$primary_uid" default default 1d >/dev/null 2>&1
"${gpg_batch[@]}" --passphrase '' --quick-add-uid "$primary_uid" "$extra_uid" >"$tmpdir/add.out" 2>&1

gpg --list-keys "$primary_uid" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Validator AddUid'
validator_assert_contains "$tmpdir/out" 'Validator AddUid Extra'
validator_assert_contains "$tmpdir/out" 'validator-add-uid-extra@example.invalid'

uid_count=$(grep -c '^uid' "$tmpdir/out" || true)
[[ "$uid_count" -ge 2 ]] || {
  printf 'expected at least 2 uid entries, got %s\n' "$uid_count" >&2
  cat "$tmpdir/out" >&2
  exit 1
}

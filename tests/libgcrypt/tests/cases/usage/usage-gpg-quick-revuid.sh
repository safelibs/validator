#!/usr/bin/env bash
# @testcase: usage-gpg-quick-revuid
# @title: gpg --quick-revuid revokes a user id
# @description: Generates a key, attaches a second user id, revokes that uid with --quick-revuid, and verifies a fresh export+import shows the revoked uid is no longer presented as a live binding.
# @timeout: 180
# @tags: usage, gpg, keyring
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-quick-revuid"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"
gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
primary_uid='Validator RevUid <validator-rev-uid@example.invalid>'
extra_uid='Validator RevUid Extra <validator-rev-uid-extra@example.invalid>'

"${gpg_batch[@]}" --passphrase '' --quick-generate-key "$primary_uid" default default 1d >/dev/null 2>&1
"${gpg_batch[@]}" --passphrase '' --quick-add-uid "$primary_uid" "$extra_uid" >"$tmpdir/add.out" 2>&1

gpg --list-keys "$primary_uid" >"$tmpdir/before"
validator_assert_contains "$tmpdir/before" 'validator-rev-uid-extra@example.invalid'

"${gpg_batch[@]}" --passphrase '' --quick-revuid "$primary_uid" "$extra_uid" >"$tmpdir/rev.out" 2>&1

# Re-import into a fresh keyring so revocation propagates cleanly.
gpg --armor --export "$primary_uid" >"$tmpdir/pub.asc"
fresh_home="$tmpdir/fresh"
mkdir -p "$fresh_home"
chmod 700 "$fresh_home"
GNUPGHOME="$fresh_home" gpg --batch --import "$tmpdir/pub.asc" >/dev/null 2>&1
GNUPGHOME="$fresh_home" gpg --list-keys "$primary_uid" >"$tmpdir/after"

# The primary uid must still be present, and the extra uid must either be
# absent from the live listing or be marked [revoked].
validator_assert_contains "$tmpdir/after" 'validator-rev-uid@example.invalid'
if grep -q 'validator-rev-uid-extra@example.invalid' "$tmpdir/after"; then
  grep 'validator-rev-uid-extra@example.invalid' "$tmpdir/after" | grep -q 'revoked' || {
    printf 'extra uid still present and not marked revoked\n' >&2
    cat "$tmpdir/after" >&2
    exit 1
  }
fi

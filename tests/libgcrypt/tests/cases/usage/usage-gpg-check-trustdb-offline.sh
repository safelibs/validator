#!/usr/bin/env bash
# @testcase: usage-gpg-check-trustdb-offline
# @title: gpg check-trustdb offline
# @description: Generates a key in an isolated GNUPGHOME and runs gpg --check-trustdb to confirm the trust database walks cleanly without any network activity.
# @timeout: 180
# @tags: usage, gpg, trustdb
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-check-trustdb-offline"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
uid='Validator TrustDB <validator-trustdb@example.invalid>'

"${gpg_batch[@]}" --passphrase '' --quick-generate-key "$uid" ed25519 sign 1d >/dev/null 2>&1

# A trustdb file should now exist in the isolated home.
validator_require_file "$GNUPGHOME/trustdb.gpg"

gpg --check-trustdb >"$tmpdir/out" 2>&1
validator_assert_contains "$tmpdir/out" 'trust model'
validator_assert_contains "$tmpdir/out" 'depth:'
validator_assert_contains "$tmpdir/out" '1u'

#!/usr/bin/env bash
# @testcase: usage-gpg-no-default-keyring-isolation
# @title: gpg --no-default-keyring + --keyring isolates from default ring
# @description: Generates one key into the default GNUPGHOME pubring and another into a separate keyring file via --no-default-keyring + --keyring, then asserts each subsequent listing only sees the keyblock that lives in the keyring it was directed to.
# @timeout: 240
# @tags: usage, gpg, keyring, isolation
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-no-default-keyring-isolation"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
default_uid='Validator DefaultRing <validator-default-ring@example.invalid>'
isolated_uid='Validator IsolatedRing <validator-isolated-ring@example.invalid>'
isolated_kbx="$GNUPGHOME/isolated.kbx"

# Key #1: lands in the default pubring under GNUPGHOME.
"${gpg_batch[@]}" --passphrase '' \
  --quick-generate-key "$default_uid" ed25519 sign 1d >/dev/null 2>&1

# Key #2: lands ONLY in the isolated keyring file. --no-default-keyring
# detaches the default pubring; --keyring + --primary-keyring direct the
# write to our chosen file. gpg requires the file to exist already, so
# pre-create it as an empty placeholder.
: >"$isolated_kbx"
"${gpg_batch[@]}" \
  --no-default-keyring \
  --keyring "$isolated_kbx" \
  --primary-keyring "$isolated_kbx" \
  --passphrase '' \
  --quick-generate-key "$isolated_uid" ed25519 sign 1d >/dev/null 2>&1

test -s "$isolated_kbx"

# Default-keyring listing must see the first uid and NOT the isolated one.
gpg --no-auto-check-trustdb --list-keys >"$tmpdir/default.list" 2>/dev/null
validator_assert_contains "$tmpdir/default.list" 'validator-default-ring@example.invalid'
if grep -q 'validator-isolated-ring@example.invalid' "$tmpdir/default.list"; then
  printf 'isolated uid leaked into default keyring\n' >&2
  cat "$tmpdir/default.list" >&2
  exit 1
fi

# Isolated-keyring listing must see ONLY the isolated uid.
gpg --no-auto-check-trustdb --no-default-keyring --keyring "$isolated_kbx" \
  --list-keys >"$tmpdir/isolated.list" 2>/dev/null
validator_assert_contains "$tmpdir/isolated.list" 'validator-isolated-ring@example.invalid'
if grep -q 'validator-default-ring@example.invalid' "$tmpdir/isolated.list"; then
  printf 'default uid leaked into isolated keyring\n' >&2
  cat "$tmpdir/isolated.list" >&2
  exit 1
fi

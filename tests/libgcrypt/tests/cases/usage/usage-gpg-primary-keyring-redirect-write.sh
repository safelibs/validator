#!/usr/bin/env bash
# @testcase: usage-gpg-primary-keyring-redirect-write
# @title: gpg --primary-keyring redirects new public key writes
# @description: Generates a key with --primary-keyring pointing to a redirected keyring file inside GNUPGHOME and confirms the new public key is materialized in the redirected keyring while the default pubring.kbx stays empty of public keyblocks.
# @timeout: 240
# @tags: usage, gpg, keyring
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-primary-keyring-redirect-write"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME/extra"
chmod 700 "$GNUPGHOME"

primary_kbx="$GNUPGHOME/extra/primary.kbx"
default_kbx="$GNUPGHOME/pubring.kbx"

gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
uid='Validator PrimaryRedirect <validator-primary-redirect@example.invalid>'

# gpg refuses to use --keyring/--primary-keyring paths that don't yet exist
# ("keyblock resource ...: No such file or directory") and silently falls back
# to the default keyring. Pre-create an empty file so it adopts our path.
: >"$primary_kbx"

# Generate the keyblock writing into the redirected primary keyring.
"${gpg_batch[@]}" \
  --keyring "$primary_kbx" \
  --primary-keyring "$primary_kbx" \
  --passphrase '' \
  --quick-generate-key "$uid" ed25519 sign 1d >/dev/null 2>&1

# The redirected keyring must exist, be non-empty, and surface the new uid
# when listed via --no-default-keyring + --keyring.
test -s "$primary_kbx"
gpg --no-default-keyring --keyring "$primary_kbx" --list-keys "$uid" \
  >"$tmpdir/redirected.list"
validator_assert_contains "$tmpdir/redirected.list" 'validator-primary-redirect@example.invalid'

# The default pubring.kbx must NOT contain this keyblock. It may still exist
# as a zero-byte file (gpg can touch it to claim the path) -- what matters is
# that no public key for our uid materialized there.
if [[ -s "$default_kbx" ]]; then
  if gpg --no-default-keyring --keyring "$default_kbx" --list-keys "$uid" \
       >"$tmpdir/default.list" 2>"$tmpdir/default.err"; then
    if grep -q 'validator-primary-redirect@example.invalid' "$tmpdir/default.list"; then
      printf 'unexpected keyblock present in default keyring %s\n' "$default_kbx" >&2
      cat "$tmpdir/default.list" >&2
      exit 1
    fi
  fi
fi

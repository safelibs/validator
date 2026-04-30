#!/usr/bin/env bash
# @testcase: usage-gpg-no-tty-batch-list
# @title: gpg no-tty in batch mode
# @description: Runs gpg --no-tty --batch --list-keys against a freshly generated keyring and confirms it emits a normal listing with no terminal-tied prompts even when stdin is closed.
# @timeout: 180
# @tags: usage, gpg, batch, listing
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-no-tty-batch-list"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
uid='Validator NoTTY <validator-notty@example.invalid>'

"${gpg_batch[@]}" --passphrase '' --quick-generate-key "$uid" ed25519 sign 1d >/dev/null 2>&1

# Drop stdin to simulate no controlling terminal; --no-tty must keep gpg quiet.
gpg --no-tty --batch --list-keys "$uid" </dev/null >"$tmpdir/out" 2>"$tmpdir/err"
validator_assert_contains "$tmpdir/out" 'pub'
validator_assert_contains "$tmpdir/out" "$uid"

if grep -Eq 'gpg: cannot open .*tty|prompt' "$tmpdir/err"; then
  printf 'gpg --no-tty unexpectedly tried to use a tty\n' >&2
  cat "$tmpdir/err" >&2
  exit 1
fi

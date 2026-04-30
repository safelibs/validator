#!/usr/bin/env bash
# @testcase: usage-gpg-use-agent-flag-accepted
# @title: gpg use-agent and no-use-agent both accepted
# @description: Confirms gpg accepts both --use-agent and --no-use-agent without error, and that --no-use-agent is reported as obsolete-but-effectively-no-op while listing still succeeds.
# @timeout: 180
# @tags: usage, gpg, agent, options
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-use-agent-flag-accepted"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
uid='Validator Agent <validator-agent@example.invalid>'

"${gpg_batch[@]}" --passphrase '' --quick-generate-key "$uid" ed25519 sign 1d >/dev/null 2>&1

# --use-agent should be accepted and the listing must succeed.
gpg --use-agent --list-keys "$uid" >"$tmpdir/use.out" 2>"$tmpdir/use.err"
validator_assert_contains "$tmpdir/use.out" "$uid"

# --no-use-agent is obsolete in modern GnuPG but still accepted as a no-op;
# the listing must still succeed and exit zero.
gpg --no-use-agent --list-keys "$uid" >"$tmpdir/nouse.out" 2>"$tmpdir/nouse.err"
validator_assert_contains "$tmpdir/nouse.out" "$uid"

# Combined output should never report an unknown option for either flag.
if grep -Eq 'invalid option|unknown option' "$tmpdir/use.err" "$tmpdir/nouse.err"; then
  printf 'gpg rejected --use-agent or --no-use-agent\n' >&2
  cat "$tmpdir/use.err" "$tmpdir/nouse.err" >&2
  exit 1
fi

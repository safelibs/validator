#!/usr/bin/env bash
# @testcase: usage-gpg-r13-list-config-curve-includes-multiple
# @title: gpg --list-config curve advertises ed25519, cv25519, and a NIST curve
# @description: Captures cfg:curve: via --with-colons --list-config curve and asserts the configured ECC curve list includes ed25519, cv25519, and at least one NIST P-curve (nistp256/nistp384/nistp521), confirming libgcrypt's ECC curve table is exposed.
# @timeout: 60
# @tags: usage, gpg, list-config, curve
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg --with-colons --list-config curve >"$tmpdir/out"

curve_line=$(grep -E '^cfg:curve:' "$tmpdir/out" | head -n1)
[[ -n "$curve_line" ]]

case "$curve_line" in
  *ed25519*) ;;
  *) echo "ed25519 missing in: $curve_line" >&2; exit 1 ;;
esac

case "$curve_line" in
  *cv25519*) ;;
  *) echo "cv25519 missing in: $curve_line" >&2; exit 1 ;;
esac

# At least one NIST curve must be present.
echo "$curve_line" | grep -Eq 'nistp(256|384|521)'

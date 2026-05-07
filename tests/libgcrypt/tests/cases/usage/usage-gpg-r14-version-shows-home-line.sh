#!/usr/bin/env bash
# @testcase: usage-gpg-r14-version-shows-home-line
# @title: gpg --version banner advertises the active Home directory path
# @description: Runs gpg --version against an ephemeral GNUPGHOME and asserts the output banner contains a "Home:" entry pointing at the configured GNUPGHOME path, confirming gpg honors GNUPGHOME and reports it back through the --version banner.
# @timeout: 60
# @tags: usage, gpg, version, home
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg --version >"$tmpdir/out" 2>&1

# The banner has a "Home: <path>" line. Assert both that the literal label is
# present and that the configured GNUPGHOME path appears on it.
LC_ALL=C grep -E '^Home:[[:space:]]+' "$tmpdir/out" >/dev/null
LC_ALL=C grep -F "$GNUPGHOME" "$tmpdir/out" >/dev/null

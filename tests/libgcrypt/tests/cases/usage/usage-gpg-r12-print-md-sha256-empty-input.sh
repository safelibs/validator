#!/usr/bin/env bash
# @testcase: usage-gpg-r12-print-md-sha256-empty-input
# @title: gpg --print-md SHA256 of an empty file matches the known SHA-256 digest
# @description: Creates an empty file and runs gpg --print-md SHA256 against it, then strips spaces and verifies the digest equals the canonical SHA-256 of the empty string (e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855).
# @timeout: 60
# @tags: usage, gpg, digest, sha256
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

: >"$tmpdir/empty.bin"

gpg --print-md SHA256 "$tmpdir/empty.bin" >"$tmpdir/out" 2>"$tmpdir/err" || true

# gpg may print "gpg: keybox '...' created" on stderr, which can leak onto
# stdout if the caller merged streams. Read only the file-prefixed digest
# line from stdout and strip the filename header.
digest=$(awk -F: -v f="$tmpdir/empty.bin" '$0 ~ f {sub(/^[^:]*:/, ""); print}' "$tmpdir/out" \
  | tr -d ' \t\n' | tr 'A-Z' 'a-z')
expected='e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'
[[ "$digest" == "$expected" ]] || {
  printf 'sha256 mismatch: got=%s expected=%s\n' "$digest" "$expected" >&2
  cat "$tmpdir/out" >&2
  exit 1
}

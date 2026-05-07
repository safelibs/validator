#!/usr/bin/env bash
# @testcase: usage-minisign-r12-keypair-files-exist-and-nonempty
# @title: minisign -G writes both public and secret key files with non-empty content
# @description: Generates a passwordless minisign keypair into explicit paths under a tmpdir and asserts both the public and secret key files exist with non-zero size and the public key file declares the standard untrusted comment header.
# @timeout: 180
# @tags: usage, minisign, keygen
# @client: minisign

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

minisign -G -p "$tmpdir/pk" -s "$tmpdir/sk" -W

[[ -s "$tmpdir/pk" ]] || { echo 'public key file is empty' >&2; exit 1; }
[[ -s "$tmpdir/sk" ]] || { echo 'secret key file is empty' >&2; exit 1; }

# minisign public key file always begins with an untrusted comment line.
head -n1 "$tmpdir/pk" | grep -q '^untrusted comment'
head -n1 "$tmpdir/sk" | grep -q '^untrusted comment'

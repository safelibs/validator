#!/usr/bin/env bash
# @testcase: usage-minisign-pubkey-format
# @title: minisign public key format
# @description: Generates a passwordless minisign keypair and verifies the public key file carries the minisign public key comment marker.
# @timeout: 180
# @tags: usage, minisign, keygen
# @client: minisign

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-minisign-pubkey-format"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

out=$(minisign -G -p "$tmpdir/pub.key" -s "$tmpdir/sec.key" -W 2>&1 || true)
validator_require_file "$tmpdir/pub.key"
validator_assert_contains "$tmpdir/pub.key" 'minisign public key'

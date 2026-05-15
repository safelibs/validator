#!/usr/bin/env bash
# @testcase: usage-minisign-r20-two-keygens-produce-distinct-pubkeys
# @title: Two minisign -G keygens produce distinct base64 public keys
# @description: Runs minisign -G -W (passwordless) twice into separate output paths, reads the second line of each pubkey file, and asserts the two base64 public-key blobs differ byte-for-byte, confirming libsodium-backed key generation produces fresh entropy on each invocation.
# @timeout: 60
# @tags: usage, minisign, keygen, distinct, r20
# @client: minisign

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

minisign -G -W -p "$tmpdir/k1.pub" -s "$tmpdir/k1.sec" >/dev/null
minisign -G -W -p "$tmpdir/k2.pub" -s "$tmpdir/k2.sec" >/dev/null

pk1=$(sed -n '2p' "$tmpdir/k1.pub")
pk2=$(sed -n '2p' "$tmpdir/k2.pub")

[[ -n "$pk1" ]] || { echo "empty pk1" >&2; exit 1; }
[[ -n "$pk2" ]] || { echo "empty pk2" >&2; exit 1; }
[[ "$pk1" != "$pk2" ]] || { echo "pubkeys collided" >&2; exit 1; }

echo "ok pk1!=pk2"

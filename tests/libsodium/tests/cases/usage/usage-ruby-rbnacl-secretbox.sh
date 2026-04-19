#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rrbnacl -e 'key=RbNaCl::Random.random_bytes(RbNaCl::SecretBox.key_bytes); box=RbNaCl::SecretBox.new(key); nonce=RbNaCl::Random.random_bytes(box.nonce_bytes); cipher=box.encrypt(nonce, "payload"); puts box.decrypt(nonce, cipher)'
#!/usr/bin/env bash
# @testcase: usage-ruby-rbnacl-simplebox-roundtrip
# @title: RbNaCl SimpleBox roundtrip
# @description: Encrypts and decrypts a payload with RbNaCl::SimpleBox via libsodium and asserts the plaintext round-trips exactly.
# @timeout: 180
# @tags: usage, crypto, ruby
# @client: ruby-rbnacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rrbnacl -e '
key = ("\x00".b * RbNaCl::SecretBox.key_bytes)
box = RbNaCl::SimpleBox.from_secret_key(key)
plaintext = "the quick brown fox jumps over the lazy dog"
ciphertext = box.encrypt(plaintext)
raise "ciphertext same as plaintext" if ciphertext == plaintext
recovered = box.decrypt(ciphertext)
raise "roundtrip mismatch: #{recovered.inspect}" unless recovered == plaintext
puts "ok #{recovered.bytesize}"
'

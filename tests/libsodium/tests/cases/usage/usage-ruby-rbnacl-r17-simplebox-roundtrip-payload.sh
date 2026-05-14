#!/usr/bin/env bash
# @testcase: usage-ruby-rbnacl-r17-simplebox-roundtrip-payload
# @title: RbNaCl::SimpleBox round-trips a fixed payload using a 32-byte key
# @description: Builds a SimpleBox from a 32-byte key sized by RbNaCl::SecretBox::KEY_BYTES, encrypts a fixed payload, asserts the ciphertext is a String of bytesize >= plaintext length plus RbNaCl::SecretBox::NONCE_BYTES + RbNaCl::SecretBox::TAG_BYTES (24 + 16), decrypts and asserts the recovered plaintext equals the original byte-for-byte.
# @timeout: 60
# @tags: usage, crypto, simplebox, ruby, r17
# @client: ruby-rbnacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rrbnacl -e '
key = ("\x17".b * RbNaCl::SecretBox::KEY_BYTES)
box = RbNaCl::SimpleBox.from_secret_key(key)
plain = "r17 rbnacl simplebox payload".b

ct = box.encrypt(plain)
raise "ct type=#{ct.class}" unless ct.is_a?(String)
min = plain.bytesize + RbNaCl::SecretBox::NONCE_BYTES + RbNaCl::SecretBox::TAG_BYTES
raise "ct=#{ct.bytesize} min=#{min}" unless ct.bytesize >= min

pt = box.decrypt(ct)
raise "roundtrip mismatch" unless pt == plain
puts "ok ct=#{ct.bytesize}"
'

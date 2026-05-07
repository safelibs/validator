#!/usr/bin/env bash
# @testcase: usage-ruby-rbnacl-r15-secretbox-empty-message
# @title: RbNaCl SecretBox encrypts and decrypts a zero-length message
# @description: Builds an RbNaCl::SecretBox from a fixed 32-byte key, encrypts an empty (zero-byte) message under a 24-byte nonce, asserts the resulting ciphertext is exactly RbNaCl::SecretBox.tag_bytes (16) bytes (just the MAC, no plaintext bytes), decrypts back and asserts the recovered plaintext is an empty binary string.
# @timeout: 180
# @tags: usage, crypto, secretbox, empty, ruby, r15
# @client: ruby-rbnacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rrbnacl -e '
key = ("\x15".b * RbNaCl::SecretBox.key_bytes)
nonce = ("\x01".b * RbNaCl::SecretBox.nonce_bytes)

box = RbNaCl::SecretBox.new(key)
plain = "".b

ct = box.encrypt(nonce, plain)
expected = RbNaCl::SecretBox.tag_bytes
raise "ct length: #{ct.bytesize} != #{expected}" unless ct.bytesize == expected

pt = box.decrypt(nonce, ct)
raise "decrypt did not return empty: #{pt.bytesize}" unless pt.bytesize == 0
raise "decrypt produced non-empty bytes: #{pt.inspect}" unless pt == "".b

puts "ok #{ct.bytesize}"
'

#!/usr/bin/env bash
# @testcase: usage-ruby-rbnacl-r15-secretbox-empty-message
# @title: RbNaCl SecretBox encrypts and decrypts a zero-length message
# @description: Builds an RbNaCl::SecretBox from a fixed 32-byte key, encrypts an empty (zero-byte) message under a 24-byte nonce, asserts the resulting ciphertext is exactly 16 bytes (the libsodium crypto_secretbox MAC, with no plaintext bytes), decrypts back and asserts the recovered plaintext is an empty binary string. (RbNaCl 7.x does not expose SecretBox.tag_bytes; the MAC length is fixed at 16.)
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
expected = 16  # libsodium crypto_secretbox MAC length (Poly1305).
raise "ct length: #{ct.bytesize} != #{expected}" unless ct.bytesize == expected

pt = box.decrypt(nonce, ct)
raise "decrypt did not return empty: #{pt.bytesize}" unless pt.bytesize == 0
raise "decrypt produced non-empty bytes: #{pt.inspect}" unless pt == "".b

puts "ok #{ct.bytesize}"
'

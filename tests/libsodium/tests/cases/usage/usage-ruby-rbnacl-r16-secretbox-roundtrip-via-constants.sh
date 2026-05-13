#!/usr/bin/env bash
# @testcase: usage-ruby-rbnacl-r16-secretbox-roundtrip-via-constants
# @title: RbNaCl::SecretBox roundtrips a payload using KEYBYTES and NONCEBYTES constants
# @description: Builds a SecretBox from a 32-byte key sized by RbNaCl::SecretBox::KEYBYTES, encrypts a fixed payload under a nonce sized by RbNaCl::SecretBox::NONCEBYTES, asserts the ciphertext is exactly plaintext-length plus 16 (Poly1305 MAC), decrypts and asserts the recovered plaintext equals the original byte-for-byte.
# @timeout: 60
# @tags: usage, crypto, secretbox, ruby, r16
# @client: ruby-rbnacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rrbnacl -e '
key = ("\x16".b * RbNaCl::SecretBox::KEYBYTES)
nonce = ("\x07".b * RbNaCl::SecretBox::NONCEBYTES)
box = RbNaCl::SecretBox.new(key)

raise "key const #{RbNaCl::SecretBox::KEYBYTES}" unless RbNaCl::SecretBox::KEYBYTES == 32
raise "nonce const #{RbNaCl::SecretBox::NONCEBYTES}" unless RbNaCl::SecretBox::NONCEBYTES == 24

plain = "r16 rbnacl secretbox payload".b
ct = box.encrypt(nonce, plain)
expected = plain.bytesize + 16
raise "ct=#{ct.bytesize} expected=#{expected}" unless ct.bytesize == expected

pt = box.decrypt(nonce, ct)
raise "roundtrip mismatch" unless pt == plain
puts "ok ct=#{ct.bytesize}"
'

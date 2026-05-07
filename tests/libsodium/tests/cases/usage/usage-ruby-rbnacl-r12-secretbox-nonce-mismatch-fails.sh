#!/usr/bin/env bash
# @testcase: usage-ruby-rbnacl-r12-secretbox-nonce-mismatch-fails
# @title: RbNaCl SecretBox decrypt fails when nonce differs from encrypt nonce
# @description: Encrypts a payload with RbNaCl::SecretBox under a 32-byte key and a specific 24-byte nonce, asserts decrypt with the original nonce returns the plaintext, then asserts decrypt with a different nonce raises RbNaCl::CryptoError.
# @timeout: 180
# @tags: usage, crypto, ruby, secretbox, nonce
# @client: ruby-rbnacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rrbnacl -e '
key = ("K" * 32).b
nonce_a = ("a" * 24).b
nonce_b = ("b" * 24).b
msg = "rbnacl r12 nonce mismatch payload".b

box = RbNaCl::SecretBox.new(key)
ct = box.encrypt(nonce_a, msg)

abort "round-trip mismatch" unless box.decrypt(nonce_a, ct) == msg

begin
  box.decrypt(nonce_b, ct)
  abort "wrong-nonce decrypt was accepted"
rescue RbNaCl::CryptoError
  puts "ok"
end
'

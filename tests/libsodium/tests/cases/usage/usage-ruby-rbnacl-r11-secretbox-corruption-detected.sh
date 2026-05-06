#!/usr/bin/env bash
# @testcase: usage-ruby-rbnacl-r11-secretbox-corruption-detected
# @title: RbNaCl SecretBox raises CryptoError when ciphertext is mutated
# @description: Encrypts a payload with RbNaCl::SecretBox under a 32-byte key and 24-byte nonce, decrypts the original ciphertext to recover the plaintext, then flips a single byte of the ciphertext and asserts that the decrypt call raises RbNaCl::CryptoError instead of silently returning forged plaintext.
# @timeout: 180
# @tags: usage, crypto, ruby, secretbox
# @client: ruby-rbnacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rrbnacl -e '
key = ("k" * 32).b
nonce = ("n" * 24).b
msg = "rbnacl r11 secretbox payload".b

box = RbNaCl::SecretBox.new(key)
ct = box.encrypt(nonce, msg)
abort "ciphertext == plaintext" if ct == msg
abort "round-trip mismatch" unless box.decrypt(nonce, ct) == msg

mutated = ct.dup
mutated.setbyte(0, mutated.getbyte(0) ^ 0x01)
begin
  box.decrypt(nonce, mutated)
  abort "forged ciphertext was accepted"
rescue RbNaCl::CryptoError
  puts "ok"
end
'

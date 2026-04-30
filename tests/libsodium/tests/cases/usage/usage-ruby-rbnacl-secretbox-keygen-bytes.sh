#!/usr/bin/env bash
# @testcase: usage-ruby-rbnacl-secretbox-keygen-bytes
# @title: RbNaCl SecretBox key/nonce/MAC byte-length constants
# @description: Allocates a fresh RbNaCl::Random.random_bytes secret-box key, constructs an RbNaCl::SecretBox, and asserts SecretBox::KEYBYTES, key_bytes (instance accessor), nonce_bytes, and tag_bytes all match the libsodium XSalsa20-Poly1305 wire constants (32, 24, 16). Then encrypts a known payload and verifies the ciphertext is exactly plaintext_len + tag_bytes long, confirming the underlying crypto_secretbox MAC accounting.
# @timeout: 180
# @tags: usage, crypto, secretbox, ruby
# @client: ruby-rbnacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rrbnacl -e '
key = RbNaCl::Random.random_bytes(RbNaCl::SecretBox::KEYBYTES)
raise "unexpected key length: #{key.bytesize}" unless key.bytesize == 32

box = RbNaCl::SecretBox.new(key)
raise "SecretBox::KEYBYTES != 32" unless RbNaCl::SecretBox::KEYBYTES == 32
raise "SecretBox::NONCEBYTES != 24" unless RbNaCl::SecretBox::NONCEBYTES == 24
raise "instance key_bytes != 32" unless box.key_bytes == 32
raise "instance nonce_bytes != 24" unless box.nonce_bytes == 24

# tag_bytes (Poly1305 authenticator length) is exposed on the instance.
# Some RbNaCl versions do not expose a SecretBox::MACBYTES constant, so fall
# back to the libsodium wire constant 16 if neither tag_bytes nor MACBYTES is
# available.
tag_bytes =
  if box.respond_to?(:tag_bytes)
    box.tag_bytes
  elsif RbNaCl::SecretBox.const_defined?(:MACBYTES)
    RbNaCl::SecretBox::MACBYTES
  else
    16
  end
raise "unexpected tag_bytes: #{tag_bytes}" unless tag_bytes == 16

nonce = ("\x00".b * box.nonce_bytes)
plaintext = "rbnacl secretbox length payload"
ciphertext = box.encrypt(nonce, plaintext)
expected_len = plaintext.bytesize + tag_bytes
raise "ciphertext length #{ciphertext.bytesize} != expected #{expected_len}" unless ciphertext.bytesize == expected_len

recovered = box.decrypt(nonce, ciphertext)
raise "roundtrip mismatch" unless recovered == plaintext

puts "ok #{ciphertext.bytesize}"
'

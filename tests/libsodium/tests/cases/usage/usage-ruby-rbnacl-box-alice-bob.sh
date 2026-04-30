#!/usr/bin/env bash
# @testcase: usage-ruby-rbnacl-box-alice-bob
# @title: RbNaCl Box Curve25519XSalsa20Poly1305 Alice-to-Bob roundtrip
# @description: Builds Alice and Bob curve25519 keypairs from deterministic seeds via RbNaCl::PrivateKey.new, encrypts a payload with RbNaCl::Box on Alice's side, decrypts on Bob's side, and asserts the recovered plaintext matches.
# @timeout: 180
# @tags: usage, crypto, ruby
# @client: ruby-rbnacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rrbnacl -e '
alice_sk = RbNaCl::PrivateKey.new("\x55".b * 32)
bob_sk = RbNaCl::PrivateKey.new("\x66".b * 32)
alice_box = RbNaCl::Box.new(bob_sk.public_key, alice_sk)
bob_box = RbNaCl::Box.new(alice_sk.public_key, bob_sk)
nonce = "\x00".b * RbNaCl::Box.nonce_bytes
plaintext = "alice -> bob via curve25519xsalsa20poly1305"
ciphertext = alice_box.encrypt(nonce, plaintext)
raise "ciphertext same as plaintext" if ciphertext == plaintext
recovered = bob_box.decrypt(nonce, ciphertext)
raise "roundtrip mismatch" unless recovered == plaintext
raise "ciphertext too short" unless ciphertext.bytesize == plaintext.bytesize + 16
puts "ok #{recovered.bytesize}"
'

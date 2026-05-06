#!/usr/bin/env bash
# @testcase: usage-ruby-rbnacl-r10-private-key-derive-public
# @title: RbNaCl PrivateKey derives matching PublicKey
# @description: Generates a Curve25519 PrivateKey via RbNaCl::PrivateKey.generate, reads back its 32-byte public_key bytes, reconstructs a PublicKey from those bytes, and asserts a Box built from the reconstructed peer public key encrypts a message that the original keypair can decrypt.
# @timeout: 180
# @tags: usage, crypto, ruby
# @client: ruby-rbnacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rrbnacl -e '
alice_sk = RbNaCl::PrivateKey.generate
bob_sk   = RbNaCl::PrivateKey.generate

alice_pk_bytes = alice_sk.public_key.to_bytes
abort "wrong public key length" unless alice_pk_bytes.bytesize == 32

reconstructed = RbNaCl::PublicKey.new(alice_pk_bytes)
abort "public key bytes mismatch" unless reconstructed.to_bytes == alice_pk_bytes

# Bob encrypts to Alice using the reconstructed public key.
sender_box = RbNaCl::Box.new(reconstructed, bob_sk)
nonce = RbNaCl::Random.random_bytes(RbNaCl::Box.nonce_bytes)
msg = "rbnacl r10 derive public payload"
ct = sender_box.encrypt(nonce, msg)

# Alice decrypts using her real secret key.
receiver_box = RbNaCl::Box.new(bob_sk.public_key, alice_sk)
pt = receiver_box.decrypt(nonce, ct)
abort "roundtrip failed" unless pt == msg
puts "ok"
'

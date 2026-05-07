#!/usr/bin/env bash
# @testcase: usage-ruby-rbnacl-r14-box-precompute-roundtrip
# @title: RbNaCl Box round-trips a payload between two keypairs in both directions
# @description: Generates two PrivateKey instances, constructs RbNaCl::Box objects for sender->receiver and receiver->sender, encrypts a payload under a fixed 24-byte nonce, asserts the receiver-side Box decrypts back to the original plaintext, and asserts the same Box decrypt with a different nonce raises CryptoError.
# @timeout: 180
# @tags: usage, crypto, box, curve25519, ruby
# @client: ruby-rbnacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rrbnacl -e '
sk_a = RbNaCl::PrivateKey.generate
sk_b = RbNaCl::PrivateKey.generate

box_ab = RbNaCl::Box.new(sk_b.public_key, sk_a)
box_ba = RbNaCl::Box.new(sk_a.public_key, sk_b)

nonce = ("\x14".b * 24)
msg = "rbnacl r14 box payload".b

ct = box_ab.encrypt(nonce, msg)
abort "ciphertext == plaintext" if ct == msg

pt = box_ba.decrypt(nonce, ct)
abort "round-trip mismatch" unless pt == msg

# Wrong nonce on decrypt must fail.
bad_nonce = ("\x15".b * 24)
rejected = false
begin
  box_ba.decrypt(bad_nonce, ct)
rescue RbNaCl::CryptoError
  rejected = true
end
abort "wrong-nonce decrypt accepted" unless rejected

puts "ok"
'

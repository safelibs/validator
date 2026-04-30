#!/usr/bin/env bash
# @testcase: usage-ruby-rbnacl-ed25519-from-seed-deterministic
# @title: RbNaCl Ed25519 SigningKey from seed is deterministic
# @description: Constructs two RbNaCl::Signatures::Ed25519::SigningKey instances from the same fixed 32-byte seed and a third from a different seed, asserts that signatures over the same message match for the matching seeds and differ for the distinct seed, that the verify keys round-trip via to_bytes, and that the corresponding VerifyKey accepts the signature for the original message and rejects a tampered message.
# @timeout: 60
# @tags: usage, crypto, signature, ruby
# @client: ruby-rbnacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rrbnacl -e '
seed_a = ("\xab".b * 32)
seed_b = ("\xcd".b * 32)
sk1 = RbNaCl::Signatures::Ed25519::SigningKey.new(seed_a)
sk2 = RbNaCl::Signatures::Ed25519::SigningKey.new(seed_a)
sk3 = RbNaCl::Signatures::Ed25519::SigningKey.new(seed_b)

raise "verify keys differ for same seed" unless sk1.verify_key.to_bytes == sk2.verify_key.to_bytes
raise "verify key length wrong: #{sk1.verify_key.to_bytes.bytesize}" unless sk1.verify_key.to_bytes.bytesize == 32
raise "verify keys match across distinct seeds" if sk1.verify_key.to_bytes == sk3.verify_key.to_bytes

message = "deterministic ed25519 seed payload"
sig1 = sk1.sign(message)
sig2 = sk2.sign(message)
sig3 = sk3.sign(message)
raise "signature length wrong: #{sig1.bytesize}" unless sig1.bytesize == 64
raise "ed25519 signatures differ across same seed" unless sig1 == sig2
raise "signatures match across distinct seeds" if sig1 == sig3

vk = RbNaCl::Signatures::Ed25519::VerifyKey.new(sk1.verify_key.to_bytes)
raise "verify failed for matching message" unless vk.verify(sig1, message)
ok = begin
  vk.verify(sig1, message + "!")
rescue RbNaCl::BadSignatureError
  :rejected
end
raise "verify accepted tampered message" unless ok == :rejected

puts "ok #{sig1.unpack1("H*")[0,16]}"
'

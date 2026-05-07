#!/usr/bin/env bash
# @testcase: usage-ruby-rbnacl-r15-signing-key-from-seed-public-bytes
# @title: RbNaCl SigningKey constructed from a fixed seed yields a deterministic 32-byte verify_key
# @description: Builds two RbNaCl::SigningKey instances from the same fixed 32-byte seed, asserts both verify_key values are 32 bytes, asserts they are equal byte-for-byte (deterministic seed -> public key derivation), and asserts a SigningKey from a different seed yields a different verify_key.
# @timeout: 180
# @tags: usage, crypto, ed25519, signing, ruby, r15
# @client: ruby-rbnacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rrbnacl -e '
seed_a = ("\x15".b * 32)
seed_b = ("\x16".b * 32)

sk_a1 = RbNaCl::SigningKey.new(seed_a)
sk_a2 = RbNaCl::SigningKey.new(seed_a)
sk_b  = RbNaCl::SigningKey.new(seed_b)

vk_a1 = sk_a1.verify_key.to_bytes
vk_a2 = sk_a2.verify_key.to_bytes
vk_b  = sk_b.verify_key.to_bytes

raise "verify_key length: #{vk_a1.bytesize}" unless vk_a1.bytesize == 32
raise "verify_key length: #{vk_a2.bytesize}" unless vk_a2.bytesize == 32
raise "verify_key length: #{vk_b.bytesize}"  unless vk_b.bytesize == 32

raise "deterministic seed produced different verify_keys" unless vk_a1 == vk_a2
raise "distinct seeds produced same verify_key" if vk_a1 == vk_b

puts "ok"
'

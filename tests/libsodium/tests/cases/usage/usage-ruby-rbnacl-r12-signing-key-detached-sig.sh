#!/usr/bin/env bash
# @testcase: usage-ruby-rbnacl-r12-signing-key-detached-sig
# @title: RbNaCl SigningKey produces verifiable Ed25519 detached signature
# @description: Creates an RbNaCl::SigningKey from a fixed seed, signs a payload, asserts the detached signature is exactly 64 bytes, verifies it via the VerifyKey, and asserts a flipped byte raises BadSignatureError.
# @timeout: 180
# @tags: usage, crypto, ruby, sign, ed25519
# @client: ruby-rbnacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rrbnacl -e '
seed = ("s" * 32).b
sk = RbNaCl::SigningKey.new(seed)
vk = sk.verify_key

msg = "rbnacl r12 detached signature payload".b
sig = sk.sign(msg)
abort "wrong sig len #{sig.bytesize}" unless sig.bytesize == 64

abort "verify failed" unless vk.verify(sig, msg)

mutated = sig.dup
mutated.setbyte(0, mutated.getbyte(0) ^ 0x01)
begin
  vk.verify(mutated, msg)
  abort "tampered signature accepted"
rescue RbNaCl::BadSignatureError
  puts "ok"
end
'

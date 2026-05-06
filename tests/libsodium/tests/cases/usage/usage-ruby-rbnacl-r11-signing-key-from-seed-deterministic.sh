#!/usr/bin/env bash
# @testcase: usage-ruby-rbnacl-r11-signing-key-from-seed-deterministic
# @title: RbNaCl SigningKey from a fixed seed produces a deterministic Ed25519 key
# @description: Constructs two RbNaCl::SigningKey instances from the identical 32-byte seed and asserts they share the same verify_key bytes, sign the same message identically, and produce 64-byte signatures that the matching verify_key accepts.
# @timeout: 180
# @tags: usage, crypto, ruby, ed25519
# @client: ruby-rbnacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rrbnacl -e '
seed = "\x11" * 32
sk1 = RbNaCl::SigningKey.new(seed)
sk2 = RbNaCl::SigningKey.new(seed)

abort "verify keys diverge for the same seed" unless sk1.verify_key.to_bytes == sk2.verify_key.to_bytes

msg = "rbnacl r11 deterministic ed25519 message"
sig1 = sk1.sign(msg)
sig2 = sk2.sign(msg)
abort "signatures diverge for the same seed" unless sig1 == sig2
abort "signature length is not 64 bytes" unless sig1.bytesize == 64

abort "verify_key rejected the signature" unless sk1.verify_key.verify(sig1, msg)
puts "ok"
'

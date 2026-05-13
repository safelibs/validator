#!/usr/bin/env bash
# @testcase: usage-ruby-rbnacl-r16-ed25519-sign-verify-known-message
# @title: RbNaCl Ed25519 SigningKey/VerifyKey sign and verify a known message with a 64-byte signature
# @description: Generates an Ed25519 SigningKey, signs a fixed message, asserts the detached signature is exactly 64 bytes, verifies the signature against the derived VerifyKey, and asserts that verifying a tampered message raises RbNaCl::BadSignatureError.
# @timeout: 60
# @tags: usage, crypto, ed25519, ruby, r16
# @client: ruby-rbnacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rrbnacl -e '
sk = RbNaCl::Signatures::Ed25519::SigningKey.generate
vk = sk.verify_key

msg = "r16 rbnacl ed25519 known message".b
sig = sk.sign(msg)
raise "sig bytesize=#{sig.bytesize}" unless sig.bytesize == 64

raise "verify failed" unless vk.verify(sig, msg)

bad = msg + "!".b
raised = false
begin
  vk.verify(sig, bad)
rescue RbNaCl::BadSignatureError
  raised = true
end
raise "tampered message accepted" unless raised
puts "ok sig=#{sig.bytesize}"
'

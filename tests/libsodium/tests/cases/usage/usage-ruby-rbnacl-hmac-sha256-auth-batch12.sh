#!/usr/bin/env bash
# @testcase: usage-ruby-rbnacl-hmac-sha256-auth-batch12
# @title: RbNaCl HMAC-SHA256 authenticate and verify
# @description: Authenticates a fixed message with RbNaCl::HMAC::SHA256 under a 32-byte key, asserts the produced tag is exactly 32 bytes, that verify accepts the matching tag, that a tampered tag raises BadAuthenticatorError, and that a different key also rejects the tag.
# @timeout: 180
# @tags: usage, crypto, mac, hmac, ruby
# @client: ruby-rbnacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rrbnacl -e '
key = ("\x44".b * 32)
message = "validator hmac-sha256 payload"
auth = RbNaCl::HMAC::SHA256.new(key)
tag = auth.auth(message)
raise "unexpected tag length: #{tag.bytesize}" unless tag.bytesize == 32

# Matching tag must verify (no exception).
auth.verify(tag, message)

# A tampered tag must be rejected.
tampered = tag.dup
tampered.setbyte(0, tampered.getbyte(0) ^ 0x01)
rejected_tampered = false
begin
  auth.verify(tampered, message)
rescue RbNaCl::BadAuthenticatorError
  rejected_tampered = true
end
raise "tampered tag accepted" unless rejected_tampered

# A wrong key must also reject the original tag.
wrong = RbNaCl::HMAC::SHA256.new(("\x45".b * 32))
rejected_wrong = false
begin
  wrong.verify(tag, message)
rescue RbNaCl::BadAuthenticatorError
  rejected_wrong = true
end
raise "wrong key accepted tag" unless rejected_wrong

# Determinism: same input under same key reproduces tag.
again = RbNaCl::HMAC::SHA256.new(key).auth(message)
raise "non-deterministic hmac" unless again == tag

puts tag.unpack1("H*")
'

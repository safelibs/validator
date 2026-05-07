#!/usr/bin/env bash
# @testcase: usage-ruby-rbnacl-r14-hmac-sha512-auth-verify
# @title: RbNaCl HMAC::SHA512 authenticate, verify, and reject tampered tag
# @description: Constructs an RbNaCl::HMAC::SHA512 instance under a 32-byte key, authenticates a fixed message, asserts the produced tag is exactly 64 bytes, asserts verify accepts the matching tag and that flipping a tag byte raises BadAuthenticatorError, and asserts re-authenticating the same input under the same key reproduces the original tag (deterministic).
# @timeout: 180
# @tags: usage, crypto, hmac, sha512, ruby
# @client: ruby-rbnacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rrbnacl -e '
key = ("\x14".b * 32)
message = "rbnacl r14 hmac-sha512 payload"

auth = RbNaCl::HMAC::SHA512.new(key)
tag = auth.auth(message)
raise "unexpected tag length: #{tag.bytesize}" unless tag.bytesize == 64

# Matching tag must verify.
auth.verify(tag, message)

# Flip one byte: must raise.
tampered = tag.dup
tampered.setbyte(0, tampered.getbyte(0) ^ 0x01)
rejected = false
begin
  auth.verify(tampered, message)
rescue RbNaCl::BadAuthenticatorError
  rejected = true
end
raise "tampered tag accepted" unless rejected

# Determinism.
again = RbNaCl::HMAC::SHA512.new(key).auth(message)
raise "non-deterministic hmac-sha512" unless again == tag

puts "ok #{tag.bytesize}"
'

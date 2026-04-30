#!/usr/bin/env bash
# @testcase: usage-ruby-rbnacl-auth-onetime
# @title: RbNaCl OneTimeAuth Poly1305 authenticate and verify
# @description: Authenticates a fixed message with RbNaCl::OneTimeAuths::Poly1305 under a 32-byte key, asserts the produced tag is exactly 16 bytes, that verify accepts the matching tag, that a tampered tag raises BadAuthenticatorError, and that a different key also rejects the tag.
# @timeout: 180
# @tags: usage, crypto, mac, ruby
# @client: ruby-rbnacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rrbnacl -e '
key = ("\x42".b * RbNaCl::OneTimeAuths::Poly1305.key_bytes)
message = "validator one-time auth payload"
auth = RbNaCl::OneTimeAuths::Poly1305.new(key)
tag = auth.auth(message)
raise "unexpected tag length: #{tag.bytesize}" unless tag.bytesize == 16

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
wrong = RbNaCl::OneTimeAuths::Poly1305.new(("\x43".b * 32))
rejected_wrong = false
begin
  wrong.verify(tag, message)
rescue RbNaCl::BadAuthenticatorError
  rejected_wrong = true
end
raise "wrong key accepted tag" unless rejected_wrong

puts tag.unpack1("H*")
'

#!/usr/bin/env bash
# @testcase: usage-ruby-rbnacl-ed25519-sign-verify
# @title: RbNaCl Ed25519 sign and verify
# @description: Builds a deterministic Ed25519 signing key from a fixed seed, signs a known message, and verifies the signature with the matching VerifyKey.
# @timeout: 180
# @tags: usage, crypto, signature, ruby
# @client: ruby-rbnacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rrbnacl -e '
seed = ("\x01".b * 32)
signing_key = RbNaCl::SigningKey.new(seed)
verify_key = signing_key.verify_key
message = "ed25519 KAT message"
signature = signing_key.sign(message)
raise "unexpected signature length" unless signature.bytesize == RbNaCl::Signatures::Ed25519::SIGNATUREBYTES
raise "verification failed" unless verify_key.verify(signature, message)
begin
  verify_key.verify(signature, message + "!")
  raise "tampered message verified"
rescue RbNaCl::BadSignatureError
  # expected
end
puts "ok #{signature.bytesize}"
'

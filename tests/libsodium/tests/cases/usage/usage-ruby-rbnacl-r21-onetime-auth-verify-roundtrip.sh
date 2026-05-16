#!/usr/bin/env bash
# @testcase: usage-ruby-rbnacl-r21-onetime-auth-verify-roundtrip
# @title: rbnacl OneTimeAuth.auth and .verify round-trip a 16-byte Poly1305 tag
# @description: Creates a 32-byte OneTimeAuth key, calls RbNaCl::OneTimeAuths::Poly1305.auth on a message, asserts the resulting tag is 16 bytes, then verifies it back via .verify and asserts the call returns true, exercising libsodium's crypto_onetimeauth Poly1305 path.
# @timeout: 60
# @tags: usage, sodium, onetimeauth, poly1305, ruby, r21
# @client: ruby-rbnacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rrbnacl - <<'RUBY'
key = RbNaCl::Random.random_bytes(RbNaCl::OneTimeAuths::Poly1305.key_bytes)
raise "key=#{key.bytesize}" unless key.bytesize == 32
ota = RbNaCl::OneTimeAuths::Poly1305.new(key)
msg = "rbnacl-r21 onetimeauth payload"
tag = ota.auth(msg)
raise "tag=#{tag.bytesize}" unless tag.bytesize == 16
ok = ota.verify(tag, msg)
raise "verify=#{ok.inspect}" unless ok == true
puts "ok tag_len=#{tag.bytesize}"
RUBY

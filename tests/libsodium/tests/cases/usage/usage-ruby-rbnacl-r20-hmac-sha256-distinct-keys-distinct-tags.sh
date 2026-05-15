#!/usr/bin/env bash
# @testcase: usage-ruby-rbnacl-r20-hmac-sha256-distinct-keys-distinct-tags
# @title: ruby-rbnacl HMAC-SHA256 with distinct keys yields distinct tags for the same message
# @description: Generates two 32-byte HMAC SHA256 keys differing by one byte, authenticates the same message under each, and asserts the two resulting 32-byte tags are byte-wise distinct (and that verify accepts each tag under its own key), confirming libsodium-backed HMAC-SHA256 mixes the key bits into the output.
# @timeout: 60
# @tags: usage, rbnacl, hmac, sha256, distinct, ruby, r20
# @client: ruby-rbnacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rrbnacl - <<'RUBY'
k1 = ("\xA0".b * 32)
k2 = k1.dup
k2.setbyte(0, k2.getbyte(0) ^ 0x01)
msg = "r20 hmac distinct payload"
t1 = RbNaCl::HMAC::SHA256.new(k1).auth(msg)
t2 = RbNaCl::HMAC::SHA256.new(k2).auth(msg)
raise "len1 #{t1.bytesize}" unless t1.bytesize == 32
raise "len2 #{t2.bytesize}" unless t2.bytesize == 32
raise "tags collided" if t1 == t2
RbNaCl::HMAC::SHA256.new(k1).verify(t1, msg)
RbNaCl::HMAC::SHA256.new(k2).verify(t2, msg)
puts "ok distinct tags"
RUBY

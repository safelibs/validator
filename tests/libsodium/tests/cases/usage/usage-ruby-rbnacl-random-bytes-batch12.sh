#!/usr/bin/env bash
# @testcase: usage-ruby-rbnacl-random-bytes-batch12
# @title: RbNaCl Random.random_bytes length and uniqueness
# @description: Calls RbNaCl::Random.random_bytes for several lengths (0, 1, 32, 1024) and asserts each return value is a binary-encoded String with the requested bytesize, then draws two independent 32-byte samples and asserts they differ (a 1-in-2**256 collision counts as a real bug).
# @timeout: 60
# @tags: usage, crypto, random, ruby
# @client: ruby-rbnacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rrbnacl -e '
[0, 1, 32, 1024].each do |n|
  buf = RbNaCl::Random.random_bytes(n)
  raise "wrong type for n=#{n}: #{buf.class}" unless buf.is_a?(String)
  raise "wrong encoding for n=#{n}: #{buf.encoding}" unless buf.encoding == Encoding::BINARY
  raise "wrong length for n=#{n}: #{buf.bytesize}" unless buf.bytesize == n
end

s1 = RbNaCl::Random.random_bytes(32)
s2 = RbNaCl::Random.random_bytes(32)
raise "two 32-byte draws collided" if s1 == s2

puts "ok #{s1.unpack1("H*")[0,8]} #{s2.unpack1("H*")[0,8]}"
'

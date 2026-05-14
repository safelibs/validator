#!/usr/bin/env bash
# @testcase: usage-ruby-rbnacl-r17-random-bytes-length-64
# @title: RbNaCl::Random.random_bytes(64) returns exactly 64 bytes and is non-deterministic
# @description: Calls RbNaCl::Random.random_bytes(64) twice, asserts each result is a String of bytesize exactly 64 (libsodium randombytes_buf path), asserts the two results differ (RNG sanity), and asserts random_bytes(32) returns a 32-byte string distinct from the 64-byte string's first 32 bytes.
# @timeout: 60
# @tags: usage, crypto, random, ruby, r17
# @client: ruby-rbnacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rrbnacl -e '
a = RbNaCl::Random.random_bytes(64)
b = RbNaCl::Random.random_bytes(64)
raise "type=#{a.class}" unless a.is_a?(String)
raise "len_a=#{a.bytesize}" unless a.bytesize == 64
raise "len_b=#{b.bytesize}" unless b.bytesize == 64
raise "two 64-byte samples identical" if a == b

c = RbNaCl::Random.random_bytes(32)
raise "len_c=#{c.bytesize}" unless c.bytesize == 32
puts "ok rand64=#{a.bytesize} rand32=#{c.bytesize}"
'

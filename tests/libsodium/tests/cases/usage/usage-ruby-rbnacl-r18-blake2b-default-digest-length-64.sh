#!/usr/bin/env bash
# @testcase: usage-ruby-rbnacl-r18-blake2b-default-digest-length-64
# @title: RbNaCl::Hash::Blake2b.digest returns a 64-byte default digest and is deterministic
# @description: Calls RbNaCl::Hash::Blake2b.digest twice on the same fixed input with no extra arguments, asserts both results are 64-byte binary strings (libsodium generichash default), asserts they are byte-for-byte equal (deterministic), then calls digest on a different input and asserts the result is a 64-byte string distinct from the original digest.
# @timeout: 60
# @tags: usage, crypto, hash, blake2b, ruby, r18
# @client: ruby-rbnacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rrbnacl -e '
a1 = RbNaCl::Hash.blake2b("r18 rbnacl blake2b input")
a2 = RbNaCl::Hash.blake2b("r18 rbnacl blake2b input")
b  = RbNaCl::Hash.blake2b("r18 rbnacl blake2b different")
raise "len_a1=#{a1.bytesize}" unless a1.bytesize == 64
raise "len_a2=#{a2.bytesize}" unless a2.bytesize == 64
raise "len_b=#{b.bytesize}"   unless b.bytesize == 64
raise "non-deterministic" unless a1 == a2
raise "two distinct inputs collide" if a1 == b
puts "ok blake2b default=#{a1.bytesize}"
'

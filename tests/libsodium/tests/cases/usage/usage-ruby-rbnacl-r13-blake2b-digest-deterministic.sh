#!/usr/bin/env bash
# @testcase: usage-ruby-rbnacl-r13-blake2b-digest-deterministic
# @title: RbNaCl Hash::Blake2b.digest is deterministic at the requested digest size
# @description: Calls RbNaCl::Hash::Blake2b.digest twice on the same payload at digest_size 32, asserts both outputs are byte-identical and 32 bytes long, then asserts a different payload produces a different 32-byte digest.
# @timeout: 180
# @tags: usage, crypto, hash, blake2b, ruby
# @client: ruby-rbnacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rrbnacl -e '
msg = "rbnacl r13 blake2b payload".b
a = RbNaCl::Hash::Blake2b.digest(msg, digest_size: 32)
b = RbNaCl::Hash::Blake2b.digest(msg, digest_size: 32)
abort "non-deterministic Blake2b digest" unless a == b
abort "wrong digest length #{a.bytesize}" unless a.bytesize == 32

other = "rbnacl r13 different payload".b
c = RbNaCl::Hash::Blake2b.digest(other, digest_size: 32)
abort "distinct messages produced equal digest" if a == c
abort "wrong digest length #{c.bytesize}" unless c.bytesize == 32
puts "ok"
'

#!/usr/bin/env bash
# @testcase: usage-ruby-rbnacl-r20-blake2b-digest-size-controls-output
# @title: ruby-rbnacl Blake2b digest_size parameter directly controls output bytesize
# @description: Computes RbNaCl::Hash.blake2b on a fixed message at digest_size 16 and at digest_size 48, asserts the bytesize of each output equals the requested digest_size (16 and 48 respectively), and asserts the 16-byte digest equals the 16-byte prefix of the same construction's 16-byte run again (determinism check), confirming libsodium-backed Blake2b honours arbitrary digest_size selections.
# @timeout: 60
# @tags: usage, rbnacl, blake2b, digest-size, ruby, r20
# @client: ruby-rbnacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rrbnacl - <<'RUBY'
msg = "r20 blake2b digest_size payload"
d16a = RbNaCl::Hash.blake2b(msg, digest_size: 16)
d16b = RbNaCl::Hash.blake2b(msg, digest_size: 16)
d48  = RbNaCl::Hash.blake2b(msg, digest_size: 48)
raise "len16 #{d16a.bytesize}" unless d16a.bytesize == 16
raise "len48 #{d48.bytesize}" unless d48.bytesize == 48
raise "non-deterministic" unless d16a == d16b
raise "digests should differ across sizes" if d16a == d48[0, 16]
puts "ok sizes=16,48"
RUBY

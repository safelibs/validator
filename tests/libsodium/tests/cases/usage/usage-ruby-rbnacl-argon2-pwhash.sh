#!/usr/bin/env bash
# @testcase: usage-ruby-rbnacl-argon2-pwhash
# @title: RbNaCl Argon2 password hash and digest length
# @description: Derives an Argon2 hash via RbNaCl::PasswordHash.argon2 at moderate ops/mem limits, asserts the requested output digest length, and confirms the digest is deterministic for the same salt and password but changes when the password is altered.
# @timeout: 600
# @tags: usage, crypto, pwhash, ruby
# @client: ruby-rbnacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rrbnacl -e '
salt = ("\x10".b * RbNaCl::PasswordHash::Argon2::SALTBYTES)
ops = RbNaCl::PasswordHash::Argon2::OPSLIMIT_INTERACTIVE
mem = RbNaCl::PasswordHash::Argon2::MEMLIMIT_INTERACTIVE
digest_len = 32
hash_a = RbNaCl::PasswordHash.argon2("correct password", salt, ops, mem, digest_len)
raise "unexpected digest length: #{hash_a.bytesize}" unless hash_a.bytesize == digest_len
hash_b = RbNaCl::PasswordHash.argon2("correct password", salt, ops, mem, digest_len)
raise "argon2 not deterministic for same inputs" unless hash_a == hash_b
hash_c = RbNaCl::PasswordHash.argon2("wrong password", salt, ops, mem, digest_len)
raise "different passwords produced same hash" if hash_a == hash_c
puts hash_a.unpack1("H*")
'

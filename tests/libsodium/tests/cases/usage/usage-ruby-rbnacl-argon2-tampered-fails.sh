#!/usr/bin/env bash
# @testcase: usage-ruby-rbnacl-argon2-tampered-fails
# @title: RbNaCl Argon2 password hash deterministic and salt-sensitive
# @description: Produces Argon2 password-hash strings via RbNaCl::PasswordHash.argon2 at interactive limits, asserts the hash has the expected fixed digest length, that hashing the same password with the same 16-byte salt and parameters is deterministic, and that hashing the same password with a different salt yields a different digest.
# @timeout: 600
# @tags: usage, crypto, pwhash, ruby
# @client: ruby-rbnacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rrbnacl -e '
ops = RbNaCl::PasswordHash::Argon2::OPSLIMIT_INTERACTIVE
mem = RbNaCl::PasswordHash::Argon2::MEMLIMIT_INTERACTIVE
password = "correct horse battery staple".dup.force_encoding(Encoding::BINARY)
salt_a = ("a" * 16).dup.force_encoding(Encoding::BINARY)
salt_b = ("b" * 16).dup.force_encoding(Encoding::BINARY)
digest_size = 32

h1 = RbNaCl::PasswordHash.argon2(password, salt_a, ops, mem, digest_size)
raise "unexpected digest size #{h1.bytesize}" unless h1.bytesize == digest_size

# Same password+salt+params must be deterministic.
h2 = RbNaCl::PasswordHash.argon2(password, salt_a, ops, mem, digest_size)
raise "argon2 not deterministic for fixed salt" unless h1 == h2

# A different salt must produce a different digest.
h3 = RbNaCl::PasswordHash.argon2(password, salt_b, ops, mem, digest_size)
raise "argon2 ignored salt" if h3 == h1

# A different password under the same salt must also produce a different digest.
h4 = RbNaCl::PasswordHash.argon2("other password".dup.force_encoding(Encoding::BINARY), salt_a, ops, mem, digest_size)
raise "argon2 ignored password" if h4 == h1

puts "ok " + h1.unpack1("H*")[0, 16]
'

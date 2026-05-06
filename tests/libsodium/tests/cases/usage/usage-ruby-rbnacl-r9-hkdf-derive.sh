#!/usr/bin/env bash
# @testcase: usage-ruby-rbnacl-r9-hkdf-derive
# @title: RbNaCl Blake2b derives stable subkey
# @description: Derives a 32-byte subkey twice using RbNaCl::Hash::Blake2b with the same key and salt, and verifies both invocations produce the same digest.
# @timeout: 180
# @tags: usage, crypto, ruby
# @client: ruby-rbnacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rrbnacl -e '
key = "k" * 32
salt = "s" * 16
opts = {key: key, salt: salt, personal: "validator-r9!", digest_size: 32}
a = RbNaCl::Hash.blake2b("payload-r9", opts)
b = RbNaCl::Hash.blake2b("payload-r9", opts)
abort "non-deterministic" unless a == b
abort "wrong length" unless a.bytesize == 32
puts "ok"
'

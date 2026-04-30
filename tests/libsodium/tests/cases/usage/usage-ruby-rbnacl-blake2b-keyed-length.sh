#!/usr/bin/env bash
# @testcase: usage-ruby-rbnacl-blake2b-keyed-length
# @title: RbNaCl keyed BLAKE2b digest length
# @description: Derives a keyed BLAKE2b digest at a non-default 48-byte length and asserts the output length and that swapping the key changes the digest.
# @timeout: 180
# @tags: usage, crypto, hash, ruby
# @client: ruby-rbnacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rrbnacl -e '
key_a = ("\x02".b * 32)
key_b = ("\x03".b * 32)
message = "blake2b keyed message"
digest_a = RbNaCl::Hash.blake2b(message, key: key_a, digest_size: 48)
digest_b = RbNaCl::Hash.blake2b(message, key: key_b, digest_size: 48)
raise "unexpected digest length: #{digest_a.bytesize}" unless digest_a.bytesize == 48
raise "different keys gave matching digests" if digest_a == digest_b
again = RbNaCl::Hash.blake2b(message, key: key_a, digest_size: 48)
raise "non-deterministic digest under same key" unless again == digest_a
puts digest_a.unpack1("H*")
'

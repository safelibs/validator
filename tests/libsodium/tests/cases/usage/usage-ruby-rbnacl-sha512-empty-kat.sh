#!/usr/bin/env bash
# @testcase: usage-ruby-rbnacl-sha512-empty-kat
# @title: RbNaCl SHA-512 empty-string known-answer
# @description: Hashes the empty byte string with RbNaCl::Hash.sha512 and asserts the digest exactly matches the FIPS 180-4 SHA-512("") known-answer vector and is 64 bytes long.
# @timeout: 180
# @tags: usage, crypto, hash, kat, ruby
# @client: ruby-rbnacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rrbnacl -e '
digest = RbNaCl::Hash.sha512("".force_encoding(Encoding::BINARY))
raise "unexpected sha512 length: #{digest.bytesize}" unless digest.bytesize == 64
hex = digest.unpack1("H*")
expected = "cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e"
raise "SHA-512 empty-string KAT mismatch: #{hex}" unless hex == expected
puts hex
'

#!/usr/bin/env bash
# @testcase: usage-ruby-rbnacl-sha512-kat
# @title: RbNaCl SHA-512 known-answer
# @description: Hashes the canonical "abc" input with RbNaCl::Hash.sha512 and asserts the digest matches the FIPS 180-4 known-answer vector.
# @timeout: 180
# @tags: usage, crypto, hash, ruby
# @client: ruby-rbnacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rrbnacl -e '
digest = RbNaCl::Hash.sha512("abc")
hex = digest.unpack1("H*")
expected = "ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f"
raise "sha512 KAT mismatch: #{hex}" unless hex == expected
puts hex
'

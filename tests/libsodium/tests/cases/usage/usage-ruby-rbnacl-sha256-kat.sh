#!/usr/bin/env bash
# @testcase: usage-ruby-rbnacl-sha256-kat
# @title: RbNaCl SHA-256 known-answer
# @description: Hashes the canonical "abc" input with RbNaCl::Hash.sha256 and asserts the digest matches the FIPS 180-4 known-answer vector.
# @timeout: 180
# @tags: usage, crypto, hash, ruby
# @client: ruby-rbnacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rrbnacl -e '
digest = RbNaCl::Hash.sha256("abc")
hex = digest.unpack1("H*")
expected = "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
raise "sha256 KAT mismatch: #{hex}" unless hex == expected
puts hex
'

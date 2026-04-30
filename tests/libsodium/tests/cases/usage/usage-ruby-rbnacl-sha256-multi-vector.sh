#!/usr/bin/env bash
# @testcase: usage-ruby-rbnacl-sha256-multi-vector
# @title: RbNaCl SHA-256 multiple FIPS 180-4 vectors
# @description: Hashes a sequence of FIPS 180-4 SHA-256 known-answer inputs through RbNaCl::Hash.sha256 (the empty string, "abc", and the 56-character double-block message) and asserts each hex digest matches the published vector. Also asserts the same input hashed twice produces identical bytes, confirming the libsodium SHA-256 path is stateless and deterministic.
# @timeout: 180
# @tags: usage, crypto, hash, ruby
# @client: ruby-rbnacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rrbnacl -e '
vectors = [
  ["",
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"],
  ["abc",
   "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"],
  ["abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq",
   "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1"],
]

vectors.each do |input, expected|
  digest = RbNaCl::Hash.sha256(input)
  raise "unexpected digest length: #{digest.bytesize}" unless digest.bytesize == 32
  hex = digest.unpack1("H*")
  raise "sha256 KAT mismatch for #{input.inspect}: got #{hex}, want #{expected}" unless hex == expected
  again = RbNaCl::Hash.sha256(input)
  raise "non-deterministic sha256 for #{input.inspect}" unless again == digest
end

puts "ok #{vectors.length}"
'

#!/usr/bin/env bash
# @testcase: usage-ruby-rbnacl-blake2b-empty-input
# @title: RbNaCl BLAKE2b digest of empty input
# @description: Computes RbNaCl::Hash.blake2b on an empty string at the default 64-byte digest length and asserts the output length and that it matches the BLAKE2b-512 known answer for the empty message (786a02f742015903... as documented in RFC 7693 Appendix A and the upstream BLAKE2 reference).
# @timeout: 180
# @tags: usage, crypto, hash, ruby
# @client: ruby-rbnacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rrbnacl -e '
empty = "".b
digest = RbNaCl::Hash.blake2b(empty)
raise "unexpected digest length: #{digest.bytesize}" unless digest.bytesize == 64
expected = "786a02f742015903c6c6fd852552d272912f4740e15847618a86e217f71f5419" \
           "d25e1031afee585313896444934eb04b903a685b1448b755d56f701afe9be2ce"
got = digest.unpack1("H*")
raise "blake2b empty digest mismatch: got #{got}" unless got == expected
again = RbNaCl::Hash.blake2b(empty)
raise "blake2b not deterministic for empty input" unless again == digest
puts got
'

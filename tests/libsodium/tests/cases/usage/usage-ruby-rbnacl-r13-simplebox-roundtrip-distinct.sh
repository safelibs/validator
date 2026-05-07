#!/usr/bin/env bash
# @testcase: usage-ruby-rbnacl-r13-simplebox-roundtrip-distinct
# @title: RbNaCl SimpleBox round-trips a payload and produces distinct ciphertexts under random nonces
# @description: Builds an RbNaCl::SimpleBox from a 32-byte secret key, encrypts the same payload twice, asserts both ciphertexts decrypt back to the plaintext and that the two ciphertexts differ (random nonce embedded in SimpleBox output).
# @timeout: 180
# @tags: usage, crypto, simplebox, ruby
# @client: ruby-rbnacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rrbnacl -e '
key = RbNaCl::Random.random_bytes(32)
sb = RbNaCl::SimpleBox.from_secret_key(key)
msg = "rbnacl r13 simplebox payload".b

ct1 = sb.encrypt(msg)
ct2 = sb.encrypt(msg)

abort "ct == plain"        if ct1 == msg
abort "ct1 byteslen wrong" if ct1.bytesize <= msg.bytesize
abort "ciphertexts equal"  if ct1 == ct2

abort "round1 mismatch" unless sb.decrypt(ct1) == msg
abort "round2 mismatch" unless sb.decrypt(ct2) == msg
puts "ok"
'

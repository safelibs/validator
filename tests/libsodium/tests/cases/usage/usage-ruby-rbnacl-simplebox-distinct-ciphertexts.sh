#!/usr/bin/env bash
# @testcase: usage-ruby-rbnacl-simplebox-distinct-ciphertexts
# @title: RbNaCl::SimpleBox produces distinct ciphertexts under a fixed key
# @description: Constructs an RbNaCl::SimpleBox from a fixed 32-byte secret key, encrypts the same plaintext four times, and asserts every ciphertext is distinct (because SimpleBox prepends a freshly drawn random nonce) while every ciphertext still decrypts back to the original plaintext. Confirms RbNaCl's libsodium-backed random nonce path yields ciphertext indistinguishability across repeated SimpleBox encryptions of identical inputs.
# @timeout: 180
# @tags: usage, crypto, ruby
# @client: ruby-rbnacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rrbnacl -e '
key = ("\x42".b * RbNaCl::SecretBox.key_bytes)
box = RbNaCl::SimpleBox.from_secret_key(key)
plaintext = "validator simplebox distinct payload"

ciphertexts = Array.new(4) { box.encrypt(plaintext) }

ciphertexts.each_with_index do |ct, i|
  raise "ciphertext #{i} equals plaintext" if ct == plaintext
  raise "ciphertext #{i} too short: #{ct.bytesize}" if ct.bytesize <= plaintext.bytesize
end

distinct = ciphertexts.uniq
raise "expected distinct ciphertexts, got #{distinct.size}/#{ciphertexts.size}" \
  unless distinct.size == ciphertexts.size

ciphertexts.each_with_index do |ct, i|
  recovered = box.decrypt(ct)
  raise "decrypt mismatch at #{i}: #{recovered.inspect}" unless recovered == plaintext
end

puts "ok #{ciphertexts.size}"
'

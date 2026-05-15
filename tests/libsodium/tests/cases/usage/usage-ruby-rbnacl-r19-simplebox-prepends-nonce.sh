#!/usr/bin/env bash
# @testcase: usage-ruby-rbnacl-r19-simplebox-prepends-nonce
# @title: RbNaCl::SimpleBox encrypt output length equals plaintext + 24-byte nonce + 16-byte tag
# @description: Constructs RbNaCl::SimpleBox.from_secret_key with a 32-byte key, encrypts a fixed payload, asserts the returned ciphertext is plaintext.bytesize + 40 bytes long (24 nonce + 16 Poly1305 tag prepended), decrypts the same ciphertext via SimpleBox and asserts the recovered plaintext equals the original byte-for-byte, then asserts a second encrypt of the same plaintext yields a different ciphertext (random nonce).
# @timeout: 60
# @tags: usage, crypto, simplebox, ruby, r19
# @client: ruby-rbnacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rrbnacl -e '
key = RbNaCl::Random.random_bytes(RbNaCl::SecretBox.key_bytes)
box = RbNaCl::SimpleBox.from_secret_key(key)
msg = "r19 rbnacl simplebox payload"
ct1 = box.encrypt(msg)
raise "ct1_len=#{ct1.bytesize}" unless ct1.bytesize == msg.bytesize + 40
pt = box.decrypt(ct1)
raise "pt mismatch" unless pt == msg
ct2 = box.encrypt(msg)
raise "ct2_len=#{ct2.bytesize}" unless ct2.bytesize == msg.bytesize + 40
raise "ct duplicated (random nonce?)" if ct1 == ct2
puts "ok simplebox ct=#{ct1.bytesize} overhead=40"
'

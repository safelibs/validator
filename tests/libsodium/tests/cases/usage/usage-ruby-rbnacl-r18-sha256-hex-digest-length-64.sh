#!/usr/bin/env bash
# @testcase: usage-ruby-rbnacl-r18-sha256-hex-digest-length-64
# @title: RbNaCl::Hash.sha256 returns 32 raw bytes that hex-encode to 64 lowercase hex characters
# @description: Calls RbNaCl::Hash.sha256 on a fixed ASCII payload, asserts the result is a 32-byte binary String (libsodium SHA-256 length convention), encodes the bytes to lowercase hex via .unpack1("H*"), asserts the hex form is exactly 64 characters of [0-9a-f], and asserts a second call on the same input yields byte-identical output (deterministic).
# @timeout: 60
# @tags: usage, crypto, hash, sha256, ruby, r18
# @client: ruby-rbnacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rrbnacl -e '
msg = "r18 rbnacl sha256 input"
raw1 = RbNaCl::Hash.sha256(msg)
raw2 = RbNaCl::Hash.sha256(msg)
raise "raw_len=#{raw1.bytesize}" unless raw1.bytesize == 32
raise "non-deterministic" unless raw1 == raw2
hex = raw1.unpack1("H*")
raise "type=#{hex.class}" unless hex.is_a?(String)
raise "len=#{hex.length}" unless hex.length == 64
raise "non-hex" unless hex =~ /\A[0-9a-f]{64}\z/
puts "ok sha256 hex=#{hex.length} raw=#{raw1.bytesize}"
'

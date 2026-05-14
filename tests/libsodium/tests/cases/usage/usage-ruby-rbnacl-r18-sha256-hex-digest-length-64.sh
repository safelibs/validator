#!/usr/bin/env bash
# @testcase: usage-ruby-rbnacl-r18-sha256-hex-digest-length-64
# @title: RbNaCl::Hash::SHA256 hex_digest returns 64 lowercase hex characters
# @description: Calls RbNaCl::Hash::SHA256.hex_digest on a fixed ASCII payload, asserts the result is a String of exactly 64 characters consisting only of [0-9a-f], and asserts the raw .sha256 digest method returns a 32-byte binary String, confirming libsodium SHA-256 length conventions and hex-encoded form via RbNaCl.
# @timeout: 60
# @tags: usage, crypto, hash, sha256, ruby, r18
# @client: ruby-rbnacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rrbnacl -e '
msg = "r18 rbnacl sha256 input"
hex = RbNaCl::Hash::SHA256.hex_digest(msg)
raise "type=#{hex.class}" unless hex.is_a?(String)
raise "len=#{hex.length}" unless hex.length == 64
raise "non-hex" unless hex =~ /\A[0-9a-f]{64}\z/

raw = RbNaCl::Hash.sha256(msg)
raise "raw_len=#{raw.bytesize}" unless raw.bytesize == 32
puts "ok sha256 hex=#{hex.length} raw=#{raw.bytesize}"
'

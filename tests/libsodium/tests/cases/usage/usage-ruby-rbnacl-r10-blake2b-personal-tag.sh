#!/usr/bin/env bash
# @testcase: usage-ruby-rbnacl-r10-blake2b-personal-tag
# @title: RbNaCl Blake2b personal tag changes the digest
# @description: Hashes the same payload with RbNaCl::Hash.blake2b under two different :personal tag strings (and the same key/salt/digest_size) and asserts the resulting digests differ, confirming the personalization parameter is wired through to libsodium.
# @timeout: 180
# @tags: usage, crypto, ruby, hash
# @client: ruby-rbnacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rrbnacl -e '
key  = "k" * 32
salt = "s" * 16
msg  = "rbnacl r10 personal tag payload"

opts_a = { key: key, salt: salt, personal: "validator-aaaa", digest_size: 32 }
opts_b = { key: key, salt: salt, personal: "validator-bbbb", digest_size: 32 }

a1 = RbNaCl::Hash.blake2b(msg, opts_a)
a2 = RbNaCl::Hash.blake2b(msg, opts_a)
b1 = RbNaCl::Hash.blake2b(msg, opts_b)

abort "non-deterministic with same params" unless a1 == a2
abort "different personal must change digest" if a1 == b1
abort "wrong digest size" unless a1.bytesize == 32
abort "wrong digest size" unless b1.bytesize == 32
puts "ok"
'

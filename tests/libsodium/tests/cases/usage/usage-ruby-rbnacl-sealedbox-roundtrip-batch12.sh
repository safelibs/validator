#!/usr/bin/env bash
# @testcase: usage-ruby-rbnacl-sealedbox-roundtrip-batch12
# @title: RbNaCl SealedBox anonymous encryption round-trip
# @description: Encrypts a payload to a recipient's Curve25519 public key with RbNaCl::SealedBox.from_public_key, decrypts it back using SealedBox.from_private_key, asserts the recovered plaintext matches the original, that the ciphertext is exactly len(plaintext) + 48 bytes (32-byte ephemeral key + 16-byte Poly1305 tag), and that an unrelated recipient's secret key fails to decrypt the sealed message.
# @timeout: 180
# @tags: usage, crypto, sealedbox, ruby
# @client: ruby-rbnacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rrbnacl -e '
sk = RbNaCl::PrivateKey.generate
pk = sk.public_key
plaintext = "validator sealedbox payload"

sealer = RbNaCl::SealedBox.from_public_key(pk)
opener = RbNaCl::SealedBox.from_private_key(sk)

ct = sealer.encrypt(plaintext)
raise "unexpected sealed length: #{ct.bytesize}" unless ct.bytesize == plaintext.bytesize + 48

pt = opener.decrypt(ct)
raise "decrypt mismatch" unless pt == plaintext

# A different recipient must not be able to decrypt the sealed ciphertext.
other_sk = RbNaCl::PrivateKey.generate
other_opener = RbNaCl::SealedBox.from_private_key(other_sk)
rejected = false
begin
  other_opener.decrypt(ct)
rescue RbNaCl::CryptoError
  rejected = true
end
raise "wrong recipient decrypted sealed box" unless rejected

puts "ok #{ct.bytesize}"
'

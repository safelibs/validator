#!/usr/bin/env bash
# @testcase: usage-r-cran-sodium-pwhash-deterministic
# @title: R sodium scrypt KDF deterministic for fixed salt and password
# @description: Derives a fixed-size key with sodium::scrypt from a UTF-8 password and 32-byte salt, asserts the digest length matches the requested size, that re-running with identical inputs produces byte-identical output (deterministic scrypt KDF), and that altering either the password or the salt produces a different digest. Exercises the password-derived KDF path that R sodium exposes through libsodium.
# @timeout: 600
# @tags: usage, crypto, pwhash, r
# @client: r-cran-sodium

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

Rscript -e '
suppressMessages(library(sodium))
salt <- as.raw(rep(0x33, 32))
password <- "r sodium pwhash payload"

key_a <- scrypt(charToRaw(password), salt = salt, size = 32)
stopifnot(is.raw(key_a))
stopifnot(length(key_a) == 32)

key_b <- scrypt(charToRaw(password), salt = salt, size = 32)
stopifnot(identical(key_a, key_b))

# Different password under the same salt must change the digest.
key_other_pw <- scrypt(charToRaw("different password"), salt = salt, size = 32)
stopifnot(!identical(key_a, key_other_pw))

# Different salt under the same password must change the digest.
salt_other <- as.raw(rep(0x44, 32))
key_other_salt <- scrypt(charToRaw(password), salt = salt_other, size = 32)
stopifnot(!identical(key_a, key_other_salt))

# A different requested size produces a different-length digest.
key_64 <- scrypt(charToRaw(password), salt = salt, size = 64)
stopifnot(length(key_64) == 64)

cat("ok", length(key_a), length(key_64), "\n")
'

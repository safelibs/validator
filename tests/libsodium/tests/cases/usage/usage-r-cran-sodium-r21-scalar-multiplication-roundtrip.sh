#!/usr/bin/env bash
# @testcase: usage-r-cran-sodium-r21-scalar-multiplication-roundtrip
# @title: r-cran-sodium diffie_hellman derives identical shared secret from both sides
# @description: Generates two keygen secret keys and their corresponding pubkey() public keys, computes diffie_hellman(alice_sk, bob_pk) and diffie_hellman(bob_sk, alice_pk), and asserts both 32-byte shared-secret raw vectors are byte-for-byte identical, exercising libsodium's curve25519 scalar multiplication.
# @timeout: 60
# @tags: usage, sodium, dh, r-cran, r21
# @client: r-cran-sodium

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

Rscript -e '
suppressPackageStartupMessages(library(sodium))
a_sk <- keygen()
b_sk <- keygen()
a_pk <- pubkey(a_sk)
b_pk <- pubkey(b_sk)
ab <- diffie_hellman(a_sk, b_pk)
ba <- diffie_hellman(b_sk, a_pk)
stopifnot(length(ab) == 32L)
stopifnot(length(ba) == 32L)
stopifnot(identical(ab, ba))
cat("ok dh_len=", length(ab), "\n", sep="")
'

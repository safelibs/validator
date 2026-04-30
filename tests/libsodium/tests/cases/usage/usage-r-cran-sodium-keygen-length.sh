#!/usr/bin/env bash
# @testcase: usage-r-cran-sodium-keygen-length
# @title: R sodium keygen produces 32-byte key
# @description: Calls sodium::keygen and sodium::pubkey to confirm secret/public key byte lengths match the libsodium curve25519 constants.
# @timeout: 180
# @tags: usage, crypto, keygen, r
# @client: r-cran-sodium

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

Rscript -e '
suppressMessages(library(sodium))
sk <- keygen()
stopifnot(is.raw(sk))
stopifnot(length(sk) == 32)
pk <- pubkey(sk)
stopifnot(is.raw(pk))
stopifnot(length(pk) == 32)
stopifnot(!identical(pk, sk))
cat("ok", length(sk), length(pk), "\n")
'

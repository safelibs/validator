#!/usr/bin/env bash
# @testcase: usage-r-cran-sodium-r18-sig-keygen-roundtrip-verify
# @title: r-cran-sodium sig_keygen + sig_sign + sig_verify accept a valid Ed25519 signature
# @description: Calls sodium::sig_keygen() to obtain a 32-byte secret key seed, derives the public key with sig_pubkey(), signs a raw byte vector via sig_sign, asserts the signature is a 64-byte raw vector, then calls sig_verify with the public key and asserts the function returns TRUE for the untampered payload.
# @timeout: 60
# @tags: usage, crypto, sign, ed25519, r, r18
# @client: r-cran-sodium

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

Rscript -e '
suppressMessages(library(sodium))
sk <- sig_keygen()
stopifnot(is.raw(sk), length(sk) == 32)
pk <- sig_pubkey(sk)
stopifnot(is.raw(pk), length(pk) == 32)
msg <- charToRaw("r18 r-cran-sodium sig payload deterministic")
sig <- sig_sign(msg, sk)
stopifnot(is.raw(sig), length(sig) == 64)
ok <- sig_verify(msg, sig, pk)
stopifnot(isTRUE(ok))
cat("ok sig verified\n")
'

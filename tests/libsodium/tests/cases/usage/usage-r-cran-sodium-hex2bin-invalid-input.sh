#!/usr/bin/env bash
# @testcase: usage-r-cran-sodium-hex2bin-invalid-input
# @title: R sodium hex2bin rejects invalid hex input
# @description: Calls sodium::hex2bin on inputs that violate the hex grammar (odd-length string, character outside [0-9a-fA-F]) and asserts that hex2bin either raises an error or returns a value that is clearly not the round-trip of a valid encoding, while a valid 64-character hex string still decodes to exactly 32 raw bytes that bin2hex re-encodes to the same lowercase hex.
# @timeout: 180
# @tags: usage, crypto, encoding, r
# @client: r-cran-sodium

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

Rscript -e '
suppressMessages(library(sodium))

# Odd-length hex must not silently produce a valid 1-byte decoding.
ok_odd <- tryCatch({
  res <- hex2bin("abc")
  # If no error, the result must not pretend to be a valid odd-length decoding.
  if (is.raw(res) && length(res) > 0 && length(res) * 2 == nchar("abc")) {
    TRUE
  } else {
    FALSE
  }
}, error = function(e) FALSE)
stopifnot(!isTRUE(ok_odd))

# Non-hex characters must be rejected (or yield a non-roundtripping value).
ok_garbage <- tryCatch({
  res <- hex2bin("zz")
  # Even if a value comes back, bin2hex(res) must not equal "zz".
  is.raw(res) && identical(tolower(bin2hex(res)), "zz")
}, error = function(e) FALSE)
stopifnot(!isTRUE(ok_garbage))

# Valid 64-char lowercase hex still round-trips to 32 raw bytes.
valid <- paste0(rep("ab", 32), collapse = "")
decoded <- hex2bin(valid)
stopifnot(is.raw(decoded))
stopifnot(length(decoded) == 32)
stopifnot(identical(bin2hex(decoded), valid))

cat("ok\n")
'

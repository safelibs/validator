#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r15-deviate-flat-image-zero-stdev
# @title: ruby-vips Image#deviate of a flat uchar image is exactly 0.0
# @description: Builds a 4x4 single-band uchar image with constant 50 (zero variance) and verifies Vips::Image#deviate returns 0.0, asserting libvips' standard-deviation reducer is exactly zero on a constant image rather than a small floating-point epsilon.
# @timeout: 60
# @tags: usage, vips, ruby, deviate, stdev
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
flat = (Vips::Image.black(4, 4) + 50).cast(:uchar)
dev = flat.deviate
raise "deviate=#{dev}" unless dev == 0.0
puts "deviate flat=#{dev}"
RUBY

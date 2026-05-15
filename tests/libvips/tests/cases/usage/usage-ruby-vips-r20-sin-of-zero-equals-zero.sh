#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r20-sin-of-zero-equals-zero
# @title: ruby-vips Image#sin on a zero-valued image returns zero
# @description: Builds an 8x8 black (all zero) image, casts to float, calls .sin, and asserts the result avg, min, and max are all within 1e-9 of 0.0 (sin(0)==0), confirming libvips' libm-backed sine operator zeroes out the trivial constant.
# @timeout: 60
# @tags: usage, vips, ruby, sin, r20
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
src = Vips::Image.black(8, 8).cast(:float)
out = src.sin
raise "avg=#{out.avg}" unless out.avg.abs < 1e-9
raise "min=#{out.min}" unless out.min.abs < 1e-9
raise "max=#{out.max}" unless out.max.abs < 1e-9
puts "ok sin(0) avg=#{out.avg}"
RUBY

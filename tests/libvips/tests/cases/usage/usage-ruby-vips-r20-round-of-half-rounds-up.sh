#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r20-round-of-half-rounds-up
# @title: ruby-vips Image#round on a constant 1.7 float rounds to 2
# @description: Builds an 8x4 image with constant value 1.7 cast to float, calls .round(:rint), and asserts the result avg, min, and max are all exactly 2.0 (1.7 rounds to nearest integer 2), confirming libvips' :rint rounding mode follows standard round-to-nearest-even semantics for fractional > 0.5.
# @timeout: 60
# @tags: usage, vips, ruby, round, r20
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
src = (Vips::Image.black(8, 4) + 1.7).cast(:float)
out = src.round(:rint)
raise "avg=#{out.avg}" unless (out.avg - 2.0).abs < 1e-6
raise "min=#{out.min}" unless (out.min - 2.0).abs < 1e-6
raise "max=#{out.max}" unless (out.max - 2.0).abs < 1e-6
puts "ok round(1.7) avg=#{out.avg}"
RUBY

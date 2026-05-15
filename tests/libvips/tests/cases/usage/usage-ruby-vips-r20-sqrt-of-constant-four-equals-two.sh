#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r20-sqrt-of-constant-four-equals-two
# @title: ruby-vips Image#** 0.5 on a constant-4 image yields 2.0
# @description: Builds an 6x6 image filled with constant value 4 cast to float, raises it to the 0.5 power (square root), and asserts the result avg, min, and max are all within 1e-6 of 2.0, confirming libvips' libm-backed pow operator computes the principal square root correctly across the whole image.
# @timeout: 60
# @tags: usage, vips, ruby, sqrt, r20
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
src = (Vips::Image.black(6, 6) + 4).cast(:float)
out = src ** 0.5
raise "avg=#{out.avg}" unless (out.avg - 2.0).abs < 1e-6
raise "min=#{out.min}" unless (out.min - 2.0).abs < 1e-6
raise "max=#{out.max}" unless (out.max - 2.0).abs < 1e-6
puts "ok sqrt(4) avg=#{out.avg}"
RUBY

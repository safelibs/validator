#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r11-asin-half-degrees-thirty
# @title: ruby-vips Image#asin of 0.5 yields 30 degrees
# @description: Builds a 4x4 image of constant 0.5 and verifies Image#asin returns 30 (vips asin emits degrees, not radians) within 1e-6 tolerance.
# @timeout: 60
# @tags: usage, vips, ruby, math
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
img = (Vips::Image.black(4, 4) + 0.5).cast(:double)
v = img.asin.avg
raise "asin(0.5) got #{v}" unless (v - 30.0).abs < 1e-6
puts "asin(0.5) = #{v} degrees"
RUBY

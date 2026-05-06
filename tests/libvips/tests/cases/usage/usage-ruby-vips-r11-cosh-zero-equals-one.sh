#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r11-cosh-zero-equals-one
# @title: ruby-vips Image#cosh of zero yields one
# @description: Builds a 4x4 zero image as double and verifies Image#cosh returns the constant 1.0 (per the identity cosh(0)=1) within 1e-9 tolerance.
# @timeout: 60
# @tags: usage, vips, ruby, math, hyperbolic
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
img = Vips::Image.black(4, 4).cast(:double)
v = img.cosh.avg
raise "cosh(0) got #{v}" unless (v - 1.0).abs < 1e-9
puts "cosh(0) = #{v}"
RUBY

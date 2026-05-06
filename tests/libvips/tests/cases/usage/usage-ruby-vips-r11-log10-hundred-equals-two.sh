#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r11-log10-hundred-equals-two
# @title: ruby-vips Image#log10 of 100 yields 2
# @description: Builds a 4x4 constant-100 double image and verifies Image#log10 returns the constant 2.0 (per log10(100)=2) within 1e-9 tolerance.
# @timeout: 60
# @tags: usage, vips, ruby, math, log
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
img = (Vips::Image.black(4, 4) + 100).cast(:double)
v = img.log10.avg
raise "log10(100) got #{v}" unless (v - 2.0).abs < 1e-9
puts "log10(100) = #{v}"
RUBY

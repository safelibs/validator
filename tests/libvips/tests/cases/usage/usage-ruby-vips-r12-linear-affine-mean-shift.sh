#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r12-linear-affine-mean-shift
# @title: ruby-vips Image#linear(2, 5) maps mean 10 to 25
# @description: Builds a 5x5 constant-10 uchar image and verifies linear(a:2, b:5).avg == 25.0 exactly, asserting libvips' affine pixel transform applies a*x+b uniformly across the band.
# @timeout: 60
# @tags: usage, vips, ruby, linear, affine
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
img = (Vips::Image.black(5, 5) + 10).cast(:uchar)
v = img.linear(2, 5).avg
raise "linear avg=#{v}" unless v == 25.0
puts "linear(2,5) avg=#{v}"
RUBY

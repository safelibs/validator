#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r16-multiply-by-two-doubles-mean
# @title: ruby-vips Image#multiply(2.0) doubles the mean of a flat uchar image
# @description: Builds a 5x5 single-band uchar image with constant 40, calls Image#multiply(2.0), and asserts the result has 5x5 dimensions and a mean of exactly 80.0 — exercising libvips' multiply operator with a scalar via the explicit method form.
# @timeout: 60
# @tags: usage, vips, ruby, multiply
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
src = (Vips::Image.black(5, 5) + 40).cast(:uchar)
out = src.multiply(2.0)
raise "dims=#{out.width}x#{out.height}" unless out.width == 5 && out.height == 5
raise "avg=#{out.avg}" unless out.avg == 80.0
puts "multiply 2.0 avg=#{out.avg}"
RUBY

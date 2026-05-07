#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r15-divide-by-two-halves-mean
# @title: ruby-vips Image / 2 halves the mean of a flat uchar image
# @description: Builds a 4x4 single-band uchar image with constant 100, divides by 2 via the Ruby operator, and verifies the result's mean is 50.0, asserting libvips' arithmetic-divide on a uchar source halves the per-pixel value as expected.
# @timeout: 60
# @tags: usage, vips, ruby, divide
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
src = (Vips::Image.black(4, 4) + 100).cast(:uchar)
half = src / 2
raise "half dims=#{half.width}x#{half.height}" unless half.width == 4 && half.height == 4
raise "half avg=#{half.avg}" unless half.avg == 50.0
puts "divide /2 avg=#{half.avg}"
RUBY

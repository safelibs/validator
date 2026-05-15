#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r20-stats-on-flat-image-mean-equals-constant
# @title: ruby-vips Image#stats on a flat constant-50 image reports mean 50 and stdev 0
# @description: Builds an 8x8 image with every pixel equal to 50 (uchar), calls .stats, reads the resulting 1x6 stats image row 0 (whose layout per libvips docs is min/max/sum/sum-of-squares/mean/stdev), and asserts mean equals 50.0 and stdev equals 0.0 (flat image), confirming libvips' summary statistics operator on a constant input.
# @timeout: 60
# @tags: usage, vips, ruby, stats, r20
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
src = (Vips::Image.black(8, 8) + 50).cast(:uchar)
s = src.stats
# stats image: each column is a stat for the whole image (row 0).
# Column layout per libvips: 0=min, 1=max, 2=sum, 3=sum2, 4=mean, 5=stdev
mean = s.getpoint(4, 0).first
stdev = s.getpoint(5, 0).first
raise "mean=#{mean}" unless (mean - 50.0).abs < 1e-6
raise "stdev=#{stdev}" unless stdev.abs < 1e-6
puts "ok stats mean=#{mean} stdev=#{stdev}"
RUBY

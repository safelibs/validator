#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r14-gaussnoise-mean-near-target
# @title: ruby-vips Image.gaussnoise mean stays close to the requested target
# @description: Creates a 64x64 Gaussian noise image with mean=100 and sigma=15 via Vips::Image.gaussnoise and verifies dimensions are 64x64 with bands == 1, the per-pixel average is within +/-5 of the requested mean (broad tolerance for a stochastic generator), and the spread is non-zero (max > min after casting to uchar), asserting libvips emits a noise image with the requested distribution parameters.
# @timeout: 60
# @tags: usage, vips, ruby, gaussnoise
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
img = Vips::Image.gaussnoise(64, 64, mean: 100, sigma: 15)
raise "gaussnoise dims=#{img.width}x#{img.height}" unless img.width == 64 && img.height == 64
raise "gaussnoise bands=#{img.bands}" unless img.bands == 1
raise "gaussnoise avg=#{img.avg}" unless (img.avg - 100.0).abs < 5.0
clipped = img.cast(:uchar)
raise "gaussnoise spread lo=#{clipped.min} hi=#{clipped.max}" unless clipped.max > clipped.min
puts "gaussnoise avg=#{img.avg.round(2)} lo=#{clipped.min} hi=#{clipped.max}"
RUBY

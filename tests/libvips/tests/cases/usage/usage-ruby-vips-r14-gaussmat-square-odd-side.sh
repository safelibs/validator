#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r14-gaussmat-square-odd-side
# @title: ruby-vips Image.gaussmat produces a square mask with an odd side length
# @description: Generates a Gaussian kernel image with Vips::Image.gaussmat(2.0, 0.1) and verifies the result is square (width == height), has odd side length, and the centre pixel value strictly exceeds the corner pixel, asserting libvips' Gaussian mask generator returns a peaked, symmetric kernel suitable for convolution.
# @timeout: 60
# @tags: usage, vips, ruby, gaussmat
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
mat = Vips::Image.gaussmat(2.0, 0.1)
raise "gaussmat dims=#{mat.width}x#{mat.height}" unless mat.width > 0 && mat.height > 0
raise "gaussmat not square" unless mat.width == mat.height
raise "gaussmat side not odd: #{mat.width}" unless mat.width.odd?

centre = mat.getpoint(mat.width / 2, mat.height / 2).first
corner = mat.getpoint(0, 0).first
raise "gaussmat centre #{centre} not > corner #{corner}" unless centre > corner

puts "gaussmat side=#{mat.width} centre=#{centre.round(4)} corner=#{corner.round(4)}"
RUBY

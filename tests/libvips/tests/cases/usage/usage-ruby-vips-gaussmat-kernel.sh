#!/usr/bin/env bash
# @testcase: usage-ruby-vips-gaussmat-kernel
# @title: ruby-vips gaussmat kernel image
# @description: Generates a Gaussian kernel image with Vips::Image.gaussmat, verifies it is square with odd side length, that its peak value sits at the centre, and that the kernel is symmetric under horizontal flip.
# @timeout: 180
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

sigma = 1.5
min_ampl = 0.1
mat = Vips::Image.gaussmat(sigma, min_ampl)
raise "gaussmat dims #{mat.width}x#{mat.height}" unless mat.width > 0 && mat.height > 0
raise "gaussmat square" unless mat.width == mat.height
raise "gaussmat odd side" unless mat.width.odd?

centre_x = mat.width / 2
centre_y = mat.height / 2
peak = mat.getpoint(centre_x, centre_y).first
top_left = mat.getpoint(0, 0).first
raise "centre not peak: centre=#{peak} corner=#{top_left}" unless peak > top_left

# Mat values are non-negative.
raise "gaussmat min #{mat.min}" unless mat.min >= 0.0
# The reported max should equal the centre value.
raise "gaussmat max vs centre #{mat.max} vs #{peak}" unless (mat.max - peak).abs < 1e-6

# Symmetric under horizontal flip.
flipped = mat.fliphor
diff = (mat - flipped).abs.max
raise "gaussmat asymmetric under fliphor: diff=#{diff}" unless diff < 1e-6

puts "gaussmat side=#{mat.width} peak=#{peak.round(4)}"
RUBY

#!/usr/bin/env bash
# @testcase: usage-ruby-vips-gamma-explicit-exponent
# @title: ruby-vips gamma with explicit exponent
# @description: Applies Vips::Image#gamma with an explicit exponent of 2.2 to a uniform grey image and verifies the result is brighter than the input via avg().
# @timeout: 120
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

# Mid-grey 8x8 single band image. With exponent>1, gamma applies pixel ** (1/exp)
# to a normalised value, then rescales: a uchar mid-grey 64 should brighten.
src = (Vips::Image.black(8, 8) + 64).cast(:uchar)
raise "src dims" unless src.width == 8 && src.height == 8
raise "src avg" unless (src.avg - 64.0).abs < 0.01

out = src.gamma(exponent: 2.2)
raise "gamma dims" unless out.width == 8 && out.height == 8
raise "gamma bands" unless out.bands == 1

out_avg = out.avg
raise "gamma did not brighten: src=#{src.avg} out=#{out_avg}" unless out_avg > src.avg + 5.0

out_path = File.join(tmpdir, "gamma.png")
out.cast(:uchar).write_to_file(out_path)
raise "missing png" unless File.size?(out_path)
puts "gamma exp=2.2 src_avg=#{src.avg} out_avg=#{out_avg}"
RUBY

file "$tmpdir/gamma.png" | grep -q 'PNG image data' || { echo "not a PNG: $(file "$tmpdir/gamma.png")" >&2; exit 1; }

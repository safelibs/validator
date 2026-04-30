#!/usr/bin/env bash
# @testcase: usage-ruby-vips-conv-custom-kernel
# @title: ruby-vips conv with custom kernel matrix
# @description: Convolves a uniform image with a 3x3 box-blur kernel built via Vips::Image.new_from_array and verifies the result preserves the original constant value.
# @timeout: 180
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

# Uniform input -- a normalized box blur leaves it untouched.
src = (Vips::Image.black(16, 16) + 100).cast(:uchar)
raise "src dims" unless src.width == 16 && src.height == 16

# Sum of kernel = 9, so set scale=9 to keep magnitude.
kernel = Vips::Image.new_from_array([
  [1, 1, 1],
  [1, 1, 1],
  [1, 1, 1],
], 9)

out = src.conv(kernel, precision: :float)
raise "out dims" unless out.width == 16 && out.height == 16
raise "out bands" unless out.bands == 1

# Centre pixel must remain ~100 after the normalized blur.
centre = out.getpoint(8, 8)[0]
raise "centre #{centre}" unless (centre - 100.0).abs < 0.01

out_path = File.join(tmpdir, "conv.tif")
out.cast(:uchar).write_to_file(out_path)
raise "missing tif" unless File.size?(out_path)
puts "conv centre=#{centre}"
RUBY

file "$tmpdir/conv.tif" | grep -qE 'TIFF image data' || { echo "not a TIFF: $(file "$tmpdir/conv.tif")" >&2; exit 1; }

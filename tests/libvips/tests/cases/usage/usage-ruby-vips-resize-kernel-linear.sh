#!/usr/bin/env bash
# @testcase: usage-ruby-vips-resize-kernel-linear
# @title: ruby-vips resize with linear kernel
# @description: Downscales a uniform synthetic image with Vips::Image#resize using kernel: :linear and asserts the rescaled dimensions and that the average pixel value is preserved within tolerance.
# @timeout: 120
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

src = (Vips::Image.black(40, 40) + 90).cast(:uchar)
raise "src dims" unless src.width == 40 && src.height == 40
raise "src avg" unless (src.avg - 90.0).abs < 0.01

out = src.resize(0.5, kernel: :linear)
raise "resize dims #{out.width}x#{out.height}" unless out.width == 20 && out.height == 20
raise "resize bands" unless out.bands == 1
raise "linear avg drift" unless (out.avg - 90.0).abs < 1.0

out_path = File.join(tmpdir, "resize_linear.png")
out.cast(:uchar).write_to_file(out_path)
raise "missing png" unless File.size?(out_path)
puts "resize linear #{out.width}x#{out.height} avg=#{out.avg}"
RUBY

file "$tmpdir/resize_linear.png" | grep -q 'PNG image data' || { echo "not a PNG: $(file "$tmpdir/resize_linear.png")" >&2; exit 1; }

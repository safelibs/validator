#!/usr/bin/env bash
# @testcase: usage-ruby-vips-gaussnoise-generator
# @title: ruby-vips gaussnoise generator
# @description: Creates a Gaussian-noise image with Vips::Image.gaussnoise and verifies dimensions, band count, and that the per-pixel mean is close to the requested mean while the pixels themselves are not constant.
# @timeout: 180
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

mean = 128.0
sigma = 20.0
img = Vips::Image.gaussnoise(64, 64, mean: mean, sigma: sigma)
raise "gaussnoise dims" unless img.width == 64 && img.height == 64
raise "gaussnoise bands" unless img.bands == 1

# Average pixel value should be near the requested mean. Use a broad tolerance
# because gaussnoise is non-deterministic in general.
avg = img.avg
raise "gaussnoise avg #{avg} vs mean #{mean}" unless (avg - mean).abs < 5.0

# A real noise image should have non-zero spread (min != max). Cast to uchar
# so the comparison is well defined.
clipped = img.cast(:uchar)
lo = clipped.min
hi = clipped.max
raise "gaussnoise spread lo=#{lo} hi=#{hi}" unless hi > lo + 5

out_path = File.join(tmpdir, "gaussnoise.png")
clipped.write_to_file(out_path)
raise "missing png" unless File.size?(out_path)

reload = Vips::Image.new_from_file(out_path)
raise "reload dims" unless reload.width == 64 && reload.height == 64
puts "gaussnoise avg=#{avg.round(2)} lo=#{lo} hi=#{hi}"
RUBY

file "$tmpdir/gaussnoise.png" | grep -q 'PNG image data' || { echo "not a PNG: $(file "$tmpdir/gaussnoise.png")" >&2; exit 1; }

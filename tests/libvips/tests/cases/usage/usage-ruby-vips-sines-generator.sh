#!/usr/bin/env bash
# @testcase: usage-ruby-vips-sines-generator
# @title: ruby-vips sines synthetic generator produces a cosine wave
# @description: Generates a 2D cosine wave image with Vips::Image.sines at a known horizontal frequency and verifies the output dimensions, format, and the period of the wave along a horizontal scanline.
# @timeout: 180
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

# sines builds a 2D cosine wave: width x height, single float band, ranging
# in [-1, 1]. With horizontal frequency 4 and 0 vertical, the pattern repeats
# every (width / horfreq) pixels along a row.
width = 64
height = 32
horfreq = 4.0
img = Vips::Image.sines(width, height, hfreq: horfreq, vfreq: 0.0)
raise "sines dims" unless img.width == width && img.height == height
raise "sines bands" unless img.bands == 1
raise "sines format" unless img.format == :float || img.format == :double

# Range of values must be inside [-1, 1] (allow tiny float slop).
raise "sines max #{img.max}" unless img.max <= 1.0 + 1e-6
raise "sines min #{img.min}" unless img.min >= -1.0 - 1e-6

# At pixel x=0,y=0 cos starts at 1.0 (the libvips convention).
origin = img.getpoint(0, 0)[0]
raise "sines (0,0) #{origin}" unless (origin - 1.0).abs < 1e-3

# Period along a row is width / horfreq = 16. The pixel one period away on
# the same row should be ~ the same value.
period = (width / horfreq).to_i
raise "expected integer period" unless period == 16
later = img.getpoint(period, 0)[0]
raise "sines period #{later}" unless (later - origin).abs < 1e-3

# Vertical frequency was zero, so a different row at column 0 has the same
# value as the origin.
mid_row = img.getpoint(0, height / 2)[0]
raise "sines vert #{mid_row}" unless (mid_row - origin).abs < 1e-3

# Saving to a TIFF round-trips dimensions.
out_path = File.join(tmpdir, "sines.tif")
img.write_to_file(out_path)
raise "missing tif" unless File.size?(out_path)
reload = Vips::Image.new_from_file(out_path)
raise "reload dims" unless reload.width == width && reload.height == height

puts "sines (0,0)=#{origin.round(4)} period=#{period}"
RUBY

file "$tmpdir/sines.tif" | grep -qE 'TIFF image data' || { echo "not a TIFF: $(file "$tmpdir/sines.tif")" >&2; exit 1; }

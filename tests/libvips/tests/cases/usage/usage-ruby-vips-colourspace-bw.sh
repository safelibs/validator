#!/usr/bin/env bash
# @testcase: usage-ruby-vips-colourspace-bw
# @title: ruby-vips colourspace sRGB to B_W
# @description: Converts an sRGB image to B_W with colourspace and verifies the result has a single band plus a plausible luminance value.
# @timeout: 120
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

rgb = (Vips::Image.black(8, 8, bands: 3) + [128, 64, 200]).cast(:uchar).copy(interpretation: :srgb)
raise "rgb interp" unless rgb.interpretation == :srgb

bw = rgb.colourspace(:b_w)
raise "bw bands" unless bw.bands == 1
raise "bw size" unless bw.width == 8 && bw.height == 8

luma = bw.getpoint(4, 4)[0]
raise "bw luma out of range #{luma}" unless luma > 0 && luma < 255

out_path = File.join(tmpdir, "bw.png")
bw.cast(:uchar).write_to_file(out_path)
raise "missing png" unless File.size?(out_path)

reload = Vips::Image.new_from_file(out_path)
raise "reload bands" unless reload.bands == 1
puts "colourspace bw=#{luma.round}"
RUBY

file "$tmpdir/bw.png" | grep -q 'PNG image data' || { echo "not a PNG" >&2; exit 1; }

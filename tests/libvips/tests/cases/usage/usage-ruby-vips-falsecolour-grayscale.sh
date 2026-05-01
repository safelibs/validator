#!/usr/bin/env bash
# @testcase: usage-ruby-vips-falsecolour-grayscale
# @title: ruby-vips falsecolour expands grayscale to RGB
# @description: Applies Vips::Image#falsecolour to a single-band grayscale ramp and verifies the result is a three-band sRGB image of the same dimensions whose colours differ across distinct grayscale inputs.
# @timeout: 180
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

# Horizontal grayscale ramp 0..255 across width 256.
ramp_pixels = (0...256).to_a
gray = Vips::Image.new_from_memory(ramp_pixels.pack('C*'), 256, 1, 1, :uchar)
raise "gray bands" unless gray.bands == 1

coloured = gray.falsecolour
raise "coloured bands #{coloured.bands}" unless coloured.bands == 3
raise "coloured dims" unless coloured.width == 256 && coloured.height == 1

# Different grayscale inputs should map to different RGB triples in general.
low = coloured.getpoint(0, 0)
high = coloured.getpoint(255, 0)
raise "low rgb len" unless low.length == 3
raise "high rgb len" unless high.length == 3
raise "low == high #{low.inspect}/#{high.inspect}" if low == high

# Force evaluation by saving.
out_path = File.join(tmpdir, "false.png")
coloured.cast(:uchar).write_to_file(out_path)
raise "missing png" unless File.size?(out_path)

reload = Vips::Image.new_from_file(out_path)
raise "reload bands" unless reload.bands == 3
raise "reload dims" unless reload.width == 256 && reload.height == 1
puts "falsecolour low=#{low.inspect} high=#{high.inspect}"
RUBY

file "$tmpdir/false.png" | grep -q 'PNG image data' || { echo "not a PNG: $(file "$tmpdir/false.png")" >&2; exit 1; }

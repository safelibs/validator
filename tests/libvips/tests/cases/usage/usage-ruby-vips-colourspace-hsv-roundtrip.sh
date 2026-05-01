#!/usr/bin/env bash
# @testcase: usage-ruby-vips-colourspace-hsv-roundtrip
# @title: ruby-vips colourspace HSV round trip
# @description: Converts an sRGB image to HSV with Vips::Image#colourspace and back to sRGB, verifying that band count is preserved and that the round-tripped pixels remain close to the originals.
# @timeout: 180
# @tags: usage, ruby, image, colour
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

# 2x2 sRGB image with four distinct colours.
data = [
  200, 50,  50,    50,  200, 50,
  50,  50,  200,   180, 180, 30,
]
src = Vips::Image.new_from_memory(data.pack('C*'), 2, 2, 3, :uchar)
src = src.copy(interpretation: :srgb)
raise "bands #{src.bands}" unless src.bands == 3
raise "interp" unless src.interpretation == :srgb

hsv = src.colourspace(:hsv)
raise "hsv bands #{hsv.bands}" unless hsv.bands == 3
raise "hsv interp #{hsv.interpretation}" unless hsv.interpretation == :hsv

back = hsv.colourspace(:srgb)
raise "back bands" unless back.bands == 3
raise "back interp" unless back.interpretation == :srgb

# Each band of the round-tripped pixel should be within a small tolerance of
# the source. HSV is a lossy intermediate when going through uchar so allow
# +/- 4 levels.
(0...src.width).each do |x|
  (0...src.height).each do |y|
    s = src.getpoint(x, y)
    b = back.getpoint(x, y)
    s.zip(b).each_with_index do |(sv, bv), idx|
      diff = (sv - bv).abs
      raise "diff at #{x},#{y} band #{idx}: src=#{sv} back=#{bv}" if diff > 4
    end
  end
end

out_path = File.join(tmpdir, "hsv.png")
back.cast(:uchar).write_to_file(out_path)
raise "missing png" unless File.size?(out_path)
puts "hsv roundtrip #{src.width}x#{src.height}"
RUBY

file "$tmpdir/hsv.png" | grep -q 'PNG image data' || { echo "not a PNG: $(file "$tmpdir/hsv.png")" >&2; exit 1; }

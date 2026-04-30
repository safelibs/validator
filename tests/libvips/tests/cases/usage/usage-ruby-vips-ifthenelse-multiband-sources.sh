#!/usr/bin/env bash
# @testcase: usage-ruby-vips-ifthenelse-multiband-sources
# @title: ruby-vips ifthenelse with two multi-band source images
# @description: Builds a 1-band mask with two distinct regions plus two 3-band sRGB source images and uses Vips::Image#ifthenelse to splice the sources, verifying per-region pixel triples and the band count of the composited output.
# @timeout: 180
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

# 4x2 mask: top row all 0 (else), bottom row all 255 (then).
mask = Vips::Image.new_from_memory(
  [0, 0, 0, 0, 255, 255, 255, 255].pack('C*'),
  4, 2, 1, :uchar,
)
raise "mask bands" unless mask.bands == 1

# Two distinct 3-band source images, RGB-tagged so the ifthenelse output
# comes back as a true sRGB composite.
then_src = (Vips::Image.black(4, 2, bands: 3) + [200, 100, 50]).cast(:uchar).copy(interpretation: :srgb)
else_src = (Vips::Image.black(4, 2, bands: 3) + [10, 20, 30]).cast(:uchar).copy(interpretation: :srgb)

out = mask.ifthenelse(then_src, else_src)
raise "out bands" unless out.bands == 3
raise "out dims" unless out.width == 4 && out.height == 2

top = out.getpoint(2, 0).map { |v| v.round }
bot = out.getpoint(2, 1).map { |v| v.round }
raise "top (else) row #{top.inspect}" unless top == [10, 20, 30]
raise "bottom (then) row #{bot.inspect}" unless bot == [200, 100, 50]

out_path = File.join(tmpdir, "ifthenelse.png")
out.cast(:uchar).write_to_file(out_path)
raise "missing png" unless File.size?(out_path)

reload = Vips::Image.new_from_file(out_path)
raise "reload bands" unless reload.bands == 3
puts "ifthenelse top=#{top.inspect} bot=#{bot.inspect}"
RUBY

file "$tmpdir/ifthenelse.png" | grep -q 'PNG image data' || { echo "not a PNG: $(file "$tmpdir/ifthenelse.png")" >&2; exit 1; }

#!/usr/bin/env bash
# @testcase: usage-ruby-vips-embed-extend-background-color
# @title: ruby-vips embed extend background color
# @description: Embeds a 3-band sRGB image onto a larger canvas using Vips::Image#embed with extend :background and a non-default RGB triple, then verifies the canvas border carries the requested color while the original payload sits at the requested offset.
# @timeout: 180
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

# 2x2 sRGB image where every pixel is (50, 60, 70).
src = (Vips::Image.black(2, 2, bands: 3) + [50, 60, 70]).cast(:uchar).copy(interpretation: :srgb)
raise "src bands" unless src.bands == 3
raise "src dims" unless src.width == 2 && src.height == 2

# Embed at (1, 1) on a 4x4 canvas with extend: :background and a magenta-ish bg.
bg = [200, 30, 150]
out = src.embed(1, 1, 4, 4, extend: :background, background: bg)
raise "out dims" unless out.width == 4 && out.height == 4
raise "out bands" unless out.bands == 3

# Top-left corner is outside the source rectangle -> background.
corner = out.getpoint(0, 0).map { |v| v.round }
raise "corner #{corner.inspect}" unless corner == bg

# Far edge also outside -> background.
far = out.getpoint(3, 3).map { |v| v.round }
raise "far #{far.inspect}" unless far == bg

# Centre falls inside the embedded source -> original colour.
centre = out.getpoint(1, 1).map { |v| v.round }
raise "centre #{centre.inspect}" unless centre == [50, 60, 70]

out_path = File.join(tmpdir, "embed_bg.png")
out.cast(:uchar).write_to_file(out_path)
raise "missing png" unless File.size?(out_path)

reload = Vips::Image.new_from_file(out_path)
raise "reload bands" unless reload.bands == 3
raise "reload dims" unless reload.width == 4 && reload.height == 4
puts "embed_bg corner=#{corner.inspect} centre=#{centre.inspect}"
RUBY

file "$tmpdir/embed_bg.png" | grep -q 'PNG image data' || { echo "not a PNG: $(file "$tmpdir/embed_bg.png")" >&2; exit 1; }

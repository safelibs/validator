#!/usr/bin/env bash
# @testcase: usage-ruby-vips-composite-over
# @title: ruby-vips composite over with alpha
# @description: Composites a translucent overlay over an opaque background with mode :over and confirms band count plus center pixel blending.
# @timeout: 180
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

# Opaque red background (RGBA). Vips::Image.black yields a 'multiband'
# interpretation; composite with :over needs the inputs declared as srgb so
# the internal colourspace cast has a known route.
bg = (Vips::Image.black(8, 8, bands: 4) + [200, 0, 0, 255]).cast(:uchar).copy(interpretation: :srgb)
# Fully transparent overlay - composite over should leave bg intact
overlay = (Vips::Image.black(8, 8, bands: 4) + [0, 200, 0, 0]).cast(:uchar).copy(interpretation: :srgb)

out = bg.composite(overlay, :over)
raise "size" unless out.width == 8 && out.height == 8
raise "bands" unless out.bands == 4

centre = out.getpoint(4, 4)
raise "centre #{centre.inspect}" unless centre[0].round == 200 && centre[1].round == 0

png_path = File.join(tmpdir, "comp.png")
out.cast(:uchar).write_to_file(png_path)
raise "missing png" unless File.size?(png_path)
puts "composite #{out.width}x#{out.height} bands=#{out.bands}"
RUBY

file "$tmpdir/comp.png" | grep -q 'PNG image data' || { echo "not a PNG" >&2; exit 1; }

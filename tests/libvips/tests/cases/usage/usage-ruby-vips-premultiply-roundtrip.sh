#!/usr/bin/env bash
# @testcase: usage-ruby-vips-premultiply-roundtrip
# @title: ruby-vips premultiply unpremultiply roundtrip
# @description: Premultiplies an RGBA image and unpremultiplies the result, verifying that the recovered RGB values match the original within rounding tolerance.
# @timeout: 180
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

# RGBA image, half-transparent.
rgba = ((Vips::Image.black(8, 8, bands: 4) + [200, 100, 50, 128])
          .cast(:uchar)
          .copy(interpretation: :srgb))
raise "rgba bands" unless rgba.bands == 4
orig = rgba.getpoint(4, 4)
raise "orig #{orig.inspect}" unless orig == [200.0, 100.0, 50.0, 128.0]

pre = rgba.premultiply
raise "pre bands" unless pre.bands == 4
pre_pt = pre.getpoint(4, 4)
# alpha=128 (~0.502) so RGB should be roughly halved.
raise "pre R #{pre_pt[0]}" unless (pre_pt[0] - 200.0 * 128.0 / 255.0).abs < 1.0
raise "pre A #{pre_pt[3]}" unless (pre_pt[3] - 128.0).abs < 0.01

restored = pre.unpremultiply.cast(:uchar)
raise "restored bands" unless restored.bands == 4
back = restored.getpoint(4, 4)
raise "restored R #{back[0]}" unless (back[0] - 200.0).abs <= 1.0
raise "restored G #{back[1]}" unless (back[1] - 100.0).abs <= 1.0
raise "restored B #{back[2]}" unless (back[2] - 50.0).abs <= 1.0
raise "restored A #{back[3]}" unless (back[3] - 128.0).abs <= 1.0

out_path = File.join(tmpdir, "restored.png")
restored.write_to_file(out_path)
raise "missing png" unless File.size?(out_path)
puts "premultiply roundtrip #{back.inspect}"
RUBY

file "$tmpdir/restored.png" | grep -q 'PNG image data' || { echo "not a PNG: $(file "$tmpdir/restored.png")" >&2; exit 1; }

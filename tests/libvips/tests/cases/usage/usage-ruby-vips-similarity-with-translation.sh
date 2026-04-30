#!/usr/bin/env bash
# @testcase: usage-ruby-vips-similarity-with-translation
# @title: ruby-vips similarity with idx/idy translation
# @description: Applies Vips::Image#similarity with explicit idx/idy translation offsets in addition to a scaling factor and verifies that the output canvas grows according to the scale and that the underlying pixel value survives.
# @timeout: 180
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

src = (Vips::Image.black(20, 20) + 90).cast(:uchar)
raise "src dims" unless src.width == 20 && src.height == 20

# Pure translation (no rotation, no scale) using idx/idy; the canvas
# should keep the same dimensions but the rendered content shifts within
# the output frame.
shifted = src.similarity(angle: 0.0, scale: 1.0, idx: 3.0, idy: -2.0)
raise "translate dims #{shifted.width}x#{shifted.height}" unless shifted.width == 20 && shifted.height == 20
# A pixel well inside the original square remains 90 after a small
# translation.
centre = shifted.getpoint(10, 10)[0]
raise "translate centre #{centre}" unless (centre - 90.0).abs < 1.0

# With scale=2 plus idx/idy, the canvas doubles in size.
zoomed = src.similarity(angle: 0.0, scale: 2.0, idx: 1.0, idy: 1.0)
raise "scale dims #{zoomed.width}x#{zoomed.height}" unless zoomed.width == 40 && zoomed.height == 40
zcentre = zoomed.getpoint(20, 20)[0]
raise "scale centre #{zcentre}" unless (zcentre - 90.0).abs < 1.0

out_path = File.join(tmpdir, "similarity-translate.png")
zoomed.cast(:uchar).write_to_file(out_path)
raise "missing png" unless File.size?(out_path)

reload = Vips::Image.new_from_file(out_path)
raise "reload dims" unless reload.width == 40 && reload.height == 40
puts "similarity translate=#{centre.round} scale2=#{zcentre.round}"
RUBY

file "$tmpdir/similarity-translate.png" | grep -q 'PNG image data' || { echo "not a PNG: $(file "$tmpdir/similarity-translate.png")" >&2; exit 1; }

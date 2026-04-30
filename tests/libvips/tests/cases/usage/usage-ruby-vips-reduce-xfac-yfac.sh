#!/usr/bin/env bash
# @testcase: usage-ruby-vips-reduce-xfac-yfac
# @title: ruby-vips reduce with explicit xfac and yfac
# @description: Calls Vips::Image#reduce with distinct xfac and yfac values and verifies the resulting dimensions are scaled independently on each axis.
# @timeout: 180
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

src = ((Vips::Image.black(120, 60, bands: 3) + [80, 160, 240])
        .cast(:uchar)
        .copy(interpretation: :srgb))
raise "src dims" unless src.width == 120 && src.height == 60

# xfac=4.0 narrows width by 4x, yfac=2.0 halves height.
out = src.reduce(4.0, 2.0)
raise "reduced dims #{out.width}x#{out.height}" unless out.width == 30 && out.height == 30
raise "reduced bands" unless out.bands == 3

out_path = File.join(tmpdir, "reduced.png")
out.cast(:uchar).write_to_file(out_path)
raise "missing png" unless File.size?(out_path)

reload = Vips::Image.new_from_file(out_path)
raise "reload dims" unless reload.width == 30 && reload.height == 30
puts "reduce xfac=4 yfac=2 -> #{reload.width}x#{reload.height}"
RUBY

file "$tmpdir/reduced.png" | grep -q 'PNG image data' || { echo "not a PNG: $(file "$tmpdir/reduced.png")" >&2; exit 1; }

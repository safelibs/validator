#!/usr/bin/env bash
# @testcase: usage-ruby-vips-arrayjoin-vertical-stack
# @title: ruby-vips arrayjoin vertical stack with across:1
# @description: Stacks three single-band tiles vertically by passing across:1 to Vips::Image.arrayjoin and verifies that the resulting image is one tile wide, three tiles tall, and that the per-tile bands appear in the expected vertical positions.
# @timeout: 120
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

tw = 5
th = 3
top    = (Vips::Image.black(tw, th) + 25).cast(:uchar)
middle = (Vips::Image.black(tw, th) + 75).cast(:uchar)
bottom = (Vips::Image.black(tw, th) + 200).cast(:uchar)

stack = Vips::Image.arrayjoin([top, middle, bottom], across: 1)
raise "stack dims #{stack.width}x#{stack.height}" unless stack.width == tw && stack.height == th * 3
raise "stack bands" unless stack.bands == 1

raise "top centre"    unless stack.getpoint(2, 1).first == 25.0
raise "middle centre" unless stack.getpoint(2, th + 1).first == 75.0
raise "bottom centre" unless stack.getpoint(2, 2 * th + 1).first == 200.0

out_path = File.join(tmpdir, "stack.png")
stack.cast(:uchar).write_to_file(out_path)
raise "missing png" unless File.size?(out_path)
puts "arrayjoin down #{stack.width}x#{stack.height}"
RUBY

file "$tmpdir/stack.png" | grep -q 'PNG image data' || { echo "not a PNG: $(file "$tmpdir/stack.png")" >&2; exit 1; }

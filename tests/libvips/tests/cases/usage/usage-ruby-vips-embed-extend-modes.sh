#!/usr/bin/env bash
# @testcase: usage-ruby-vips-embed-extend-modes
# @title: ruby-vips embed extend copy and white
# @description: Embeds a small image onto a larger canvas using extend copy and extend white modes and asserts boundary pixel values.
# @timeout: 120
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

base = Vips::Image.new_from_memory([42].pack('C*'), 1, 1, 1, :uchar)

copy_out = base.embed(2, 2, 5, 5, extend: :copy)
raise "copy size" unless copy_out.width == 5 && copy_out.height == 5
raise "copy centre" unless copy_out.getpoint(2, 2) == [42.0]
raise "copy edge"   unless copy_out.getpoint(0, 0) == [42.0]
raise "copy far"    unless copy_out.getpoint(4, 4) == [42.0]

white_out = base.embed(2, 2, 5, 5, extend: :white)
raise "white centre" unless white_out.getpoint(2, 2) == [42.0]
raise "white corner" unless white_out.getpoint(0, 0) == [255.0]

out_path = File.join(tmpdir, "embed_white.png")
white_out.cast(:uchar).write_to_file(out_path)
raise "missing png" unless File.size?(out_path)
puts "embed extend ok"
RUBY

file "$tmpdir/embed_white.png" | grep -q 'PNG image data' || { echo "not a PNG" >&2; exit 1; }

#!/usr/bin/env bash
# @testcase: usage-ruby-vips-find-trim-bbox
# @title: ruby-vips find_trim bounding box
# @description: Embeds a smaller content rectangle inside a uniform background and verifies Vips::Image#find_trim returns the expected bounding box left/top/width/height tuple.
# @timeout: 120
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

bg_value = 255
content = (Vips::Image.black(6, 4) + 10).cast(:uchar)
# Embed inside a 16x12 white canvas at offset (5, 3).
canvas = content.embed(5, 3, 16, 12, extend: :white)
raise "canvas dims" unless canvas.width == 16 && canvas.height == 12

left, top, width, height = canvas.find_trim(background: [bg_value])
raise "find_trim left #{left}" unless left == 5
raise "find_trim top #{top}" unless top == 3
raise "find_trim width #{width}" unless width == 6
raise "find_trim height #{height}" unless height == 4

trimmed = canvas.crop(left, top, width, height)
raise "trim dims" unless trimmed.width == 6 && trimmed.height == 4
raise "trim pt" unless trimmed.getpoint(0, 0) == [10.0]

out_path = File.join(tmpdir, "trim.png")
trimmed.cast(:uchar).write_to_file(out_path)
raise "missing png" unless File.size?(out_path)
puts "find_trim bbox #{[left, top, width, height].inspect}"
RUBY

file "$tmpdir/trim.png" | grep -q 'PNG image data' || { echo "not a PNG: $(file "$tmpdir/trim.png")" >&2; exit 1; }

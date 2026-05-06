#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r11-minpos-locates-dark-pixel
# @title: ruby-vips Image#minpos returns value and (x,y) of darkest pixel
# @description: Draws a single 0 pixel at column 3 row 4 on a uniform-100 10x10 canvas and verifies Image#minpos returns the triple [0, 3, 4].
# @timeout: 60
# @tags: usage, vips, ruby, statistics
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
canvas = (Vips::Image.black(10, 10) + 100).cast(:uchar)
img = canvas.draw_rect(0, 3, 4, 1, 1)
v, x, y = img.minpos
raise "minpos #{[v,x,y].inspect}" unless v == 0.0 && x == 3 && y == 4
puts "minpos ok #{[v,x,y].inspect}"
RUBY

#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r9-cast-clip-overflow
# @title: ruby-vips cast to uchar clips overflow
# @description: Adds a constant that pushes pixel values above 255 and casts to uchar, verifying the cast clips at 255.
# @timeout: 120
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - <<'RUBY'
img = Vips::Image.black(4, 4, bands: 1) + 200
img = img.cast(:uchar)
big = img + 100.0           # 300, still float result
clipped = big.cast(:uchar)
raise "got #{clipped.getpoint(2, 2).inspect}" unless clipped.getpoint(2, 2) == [255.0]
raise "max #{clipped.max}" unless clipped.max == 255.0
raise "min #{clipped.min}" unless clipped.min == 255.0
RUBY

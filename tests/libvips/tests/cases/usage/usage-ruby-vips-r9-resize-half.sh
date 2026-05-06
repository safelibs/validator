#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r9-resize-half
# @title: ruby-vips resize halves dimensions
# @description: Resizes a 64x48 generated image by 0.5 and verifies the output dimensions are 32x24.
# @timeout: 120
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - <<'RUBY'
img = Vips::Image.black(64, 48, bands: 3) + [200, 100, 50]
img = img.cast(:uchar)
small = img.resize(0.5)
raise "got #{small.width}x#{small.height}" unless small.width == 32 && small.height == 24
raise "bands #{small.bands}" unless small.bands == 3
RUBY

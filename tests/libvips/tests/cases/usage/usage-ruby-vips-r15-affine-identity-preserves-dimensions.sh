#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r15-affine-identity-preserves-dimensions
# @title: ruby-vips Image#affine with the identity matrix preserves dimensions and mean
# @description: Builds an 8x8 single-band uchar constant image, applies Vips::Image#affine([1, 0, 0, 1]) (the identity transform), and verifies the result has the same 8x8 dimensions, bands == 1, and the same mean as the source, asserting libvips' affine transform with the identity matrix is value-preserving and shape-preserving.
# @timeout: 60
# @tags: usage, vips, ruby, affine, identity
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
src = (Vips::Image.black(8, 8) + 80).cast(:uchar)
aff = src.affine([1, 0, 0, 1])
raise "affine dims=#{aff.width}x#{aff.height}" unless aff.width == 8 && aff.height == 8
raise "affine bands=#{aff.bands}" unless aff.bands == 1
raise "affine avg=#{aff.avg}" unless aff.avg == 80.0
puts "affine identity ok dims=#{aff.width}x#{aff.height} avg=#{aff.avg}"
RUBY

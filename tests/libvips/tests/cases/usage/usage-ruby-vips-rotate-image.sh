#!/usr/bin/env bash
# @testcase: usage-ruby-vips-rotate-image
# @title: ruby-vips rotate image
# @description: Uses ruby-vips to run libvips rotate image behavior.
# @timeout: 180
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips -e "image=Vips::Image.black(5,9,bands:3); out=image.rot90; puts \"rot=#{out.width}x#{out.height}\"" "$tmpdir/out.png"

#!/usr/bin/env bash
# @testcase: usage-ruby-vips-crop-image
# @title: ruby-vips crop image
# @description: Uses ruby-vips to run libvips crop image behavior.
# @timeout: 180
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips -e "image=Vips::Image.black(20,10,bands:3); out=image.crop(1,1,5,4); puts \"crop=#{out.width}x#{out.height}\"" "$tmpdir/out.png"

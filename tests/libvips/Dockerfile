FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      bc \
      build-essential \
      ca-certificates \
      gir1.2-vips-8.0 \
      gobject-introspection \
      libffi-dev \
      libglib2.0-dev \
      libgirepository1.0-dev \
      libvips-dev \
      libvips-tools \
      pkg-config \
      python3 \
      python3-cffi \
      python3-pytest \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /validator

COPY _shared/ /validator/tests/_shared/
COPY libvips/ /validator/tests/libvips/

RUN chmod +x \
    /validator/tests/_shared/install_safe_debs.sh \
    /validator/tests/_shared/run_library_tests.sh \
    /validator/tests/libvips/docker-entrypoint.sh \
    /validator/tests/libvips/tests/run.sh

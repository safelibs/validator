FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      build-essential \
      ca-certificates \
      file \
      ghostscript \
      libjbig-dev \
      libjpeg-dev \
      liblzma-dev \
      libtiff-dev \
      libtiff-tools \
      libwebp-dev \
      netpbm \
      pkg-config \
      poppler-utils \
      zlib1g-dev \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /validator

COPY _shared/ /validator/tests/_shared/
COPY libtiff/ /validator/tests/libtiff/

RUN chmod +x \
    /validator/tests/_shared/install_safe_debs.sh \
    /validator/tests/_shared/run_library_tests.sh \
    /validator/tests/libtiff/docker-entrypoint.sh \
    /validator/tests/libtiff/tests/run.sh

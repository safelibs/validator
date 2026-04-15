FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      apt \
      build-essential \
      bzip2 \
      file \
      gzip \
      libacl1-dev \
      libarchive-dev \
      libarchive-tools \
      lz4 \
      lzip \
      lzop \
      pkg-config \
      python3 \
      xz-utils \
      zstd \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /validator

COPY _shared/ /validator/tests/_shared/
COPY libarchive/ /validator/tests/libarchive/

RUN chmod +x \
    /validator/tests/_shared/install_safe_debs.sh \
    /validator/tests/_shared/run_library_tests.sh \
    /validator/tests/libarchive/docker-entrypoint.sh \
    /validator/tests/libarchive/tests/run.sh

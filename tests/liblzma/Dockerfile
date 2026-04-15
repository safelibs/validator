FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      apt-utils \
      build-essential \
      dpkg-dev \
      gdb \
      libarchive-dev \
      libarchive-tools \
      libboost-iostreams-dev \
      liblzma-dev \
      libtiff-dev \
      libxml2-utils \
      pkg-config \
      python3 \
      squashfs-tools \
      xz-utils \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /validator

COPY _shared/ /validator/tests/_shared/
COPY liblzma/ /validator/tests/liblzma/

RUN chmod +x \
    /validator/tests/_shared/install_safe_debs.sh \
    /validator/tests/_shared/run_library_tests.sh \
    /validator/tests/liblzma/docker-entrypoint.sh \
    /validator/tests/liblzma/tests/run.sh

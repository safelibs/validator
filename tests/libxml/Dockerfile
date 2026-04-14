FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      build-essential \
      ca-certificates \
      file \
      liblzma-dev \
      libxml2-dev \
      libxml2-utils \
      perl \
      pkg-config \
      python3 \
      python3-libxml2 \
      xsltproc \
      zlib1g-dev \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /validator

COPY _shared/ /validator/tests/_shared/
COPY libxml/ /validator/tests/libxml/

RUN chmod +x \
    /validator/tests/_shared/install_safe_debs.sh \
    /validator/tests/_shared/run_library_tests.sh \
    /validator/tests/libxml/docker-entrypoint.sh \
    /validator/tests/libxml/tests/run.sh

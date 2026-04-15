FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      build-essential \
      pkg-config \
      python3 \
      libuv1-dev \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /validator

COPY _shared/ /validator/tests/_shared/
COPY libuv/ /validator/tests/libuv/

RUN chmod +x \
    /validator/tests/_shared/install_safe_debs.sh \
    /validator/tests/_shared/run_library_tests.sh \
    /validator/tests/libuv/docker-entrypoint.sh \
    /validator/tests/libuv/tests/run.sh

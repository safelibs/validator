FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      libjansson4 \
      libjansson-dev \
      jshon \
      bash \
      build-essential \
      coreutils \
      jq \
      pkg-config \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /validator

COPY _shared/ /validator/tests/_shared/
COPY libjansson/ /validator/tests/libjansson/

RUN find /validator/tests/_shared -maxdepth 1 -type f -name '*.sh' -exec chmod +x {} + \
 && chmod +x /validator/tests/libjansson/docker-entrypoint.sh \
 && find /validator/tests/libjansson/tests/cases -type f -name '*.sh' -exec chmod +x {} +

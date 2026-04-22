FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      curl \
      libcurl4t64 \
      libcurl4-openssl-dev \
      bash \
      build-essential \
      ca-certificates \
      coreutils \
      pkg-config \
      python3 \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /validator

COPY _shared/ /validator/tests/_shared/
COPY libcurl/ /validator/tests/libcurl/

RUN find /validator/tests/_shared -maxdepth 1 -type f -name '*.sh' -exec chmod +x {} + \
 && chmod +x /validator/tests/libcurl/docker-entrypoint.sh \
 && find /validator/tests/libcurl/tests/cases -type f -name '*.sh' -exec chmod +x {} +

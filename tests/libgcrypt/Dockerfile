FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      libgcrypt20 \
      libgcrypt20-dev \
      gpg \
      gpg-agent \
      bash \
      build-essential \
      coreutils \
      libgpg-error-dev \
      pkg-config \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /validator

COPY _shared/ /validator/tests/_shared/
COPY libgcrypt/ /validator/tests/libgcrypt/

RUN find /validator/tests/_shared -maxdepth 1 -type f -name '*.sh' -exec chmod +x {} + \
 && chmod +x /validator/tests/libgcrypt/docker-entrypoint.sh \
 && find /validator/tests/libgcrypt/tests/cases -type f -name '*.sh' -exec chmod +x {} +

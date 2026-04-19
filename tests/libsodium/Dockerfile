FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      libsodium23 \
      libsodium-dev \
      bash \
      build-essential \
      ca-certificates \
      coreutils \
      curvedns \
      fastd \
      file \
      jq \
      libtoxcore-dev \
      libzmq3-dev \
      minisign \
      nix-bin \
      php8.3-cli \
      pkg-config \
      python3 \
      python3-nacl \
      r-base-core \
      r-cran-sodium \
      ruby \
      ruby-rbnacl \
      vim \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /validator

COPY _shared/ /validator/tests/_shared/
COPY libsodium/ /validator/tests/libsodium/

RUN find /validator/tests/_shared -maxdepth 1 -type f -name '*.sh' -exec chmod +x {} + \
 && chmod +x /validator/tests/libsodium/docker-entrypoint.sh /validator/tests/libsodium/tests/run.sh \
 && if [ -d /validator/tests/libsodium/tests/cases ]; then \
      find /validator/tests/libsodium/tests/cases -type f -name '*.sh' -exec chmod +x {} +; \
    fi

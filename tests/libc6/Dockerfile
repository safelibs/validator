FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      libc6 \
      libc6-dev \
      libc-dev-bin \
      libc-bin \
      locales \
      nscd \
      bash \
      build-essential \
      coreutils \
      findutils \
      gawk \
      gcc \
      grep \
      gzip \
      python3-minimal \
      sed \
      tar \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /validator

COPY _shared/ /validator/tests/_shared/
COPY libc6/ /validator/tests/libc6/

RUN find /validator/tests/_shared -maxdepth 1 -type f -name '*.sh' -exec chmod +x {} + \
 && chmod +x /validator/tests/libc6/docker-entrypoint.sh \
 && find /validator/tests/libc6/tests/cases -type f -name '*.sh' -exec chmod +x {} +

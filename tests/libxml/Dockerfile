FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      libxml2 \
      libxml2-dev \
      libxml2-utils \
      python3-libxml2 \
      bash \
      build-essential \
      ca-certificates \
      coreutils \
      file \
      jq \
      liblzma-dev \
      perl \
      pkg-config \
      python3 \
      xsltproc \
      zlib1g-dev \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /validator

COPY _shared/ /validator/tests/_shared/
COPY libxml/ /validator/tests/libxml/

RUN find /validator/tests/_shared -maxdepth 1 -type f -name '*.sh' -exec chmod +x {} + \
 && chmod +x /validator/tests/libxml/docker-entrypoint.sh /validator/tests/libxml/tests/run.sh \
 && if [ -d /validator/tests/libxml/tests/cases ]; then \
      find /validator/tests/libxml/tests/cases -type f -name '*.sh' -exec chmod +x {} +; \
    fi

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      libsdl2-2.0-0 \
      libsdl2-dev \
      libsdl2-tests \
      python3-pygame \
      bash \
      build-essential \
      ca-certificates \
      clang \
      cmake \
      coreutils \
      dbus-x11 \
      file \
      gnome-desktop-testing \
      jq \
      libasound2-dev \
      libgl1-mesa-dri \
      libpulse-dev \
      libsdl2-ttf-dev \
      pkg-config \
      python3 \
      xvfb \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /validator

COPY _shared/ /validator/tests/_shared/
COPY libsdl/ /validator/tests/libsdl/

RUN find /validator/tests/_shared -maxdepth 1 -type f -name '*.sh' -exec chmod +x {} + \
 && chmod +x /validator/tests/libsdl/docker-entrypoint.sh /validator/tests/libsdl/tests/run.sh \
 && if [ -d /validator/tests/libsdl/tests/cases ]; then \
      find /validator/tests/libsdl/tests/cases -type f -name '*.sh' -exec chmod +x {} +; \
    fi

#!/usr/bin/env bash

set -e
set -x

sudo docker build -t weston -f Dockerfile.build .
sudo docker build -t waytest -f Dockerfile.serve .
sudo docker build -t tester -f Dockerfile.test .

# prep socket
sudo rm -rf waysocket
mkdir -p waysocket
chmod 0700 waysocket
sudo chown 0:0 waysocket

sudo docker run --rm -t -d \
  --env XDG_RUNTIME_DIR=/tmp/wayland --env WESTON_BACKEND=rdp --env WAYLAND_DEBUG=1 \
  --env MESA_DEBUG=1 --env EGL_LOG_LEVEL=error \
  --publish 13389:3389 --volume $PWD/waysocket:/tmp/wayland \
  waytest 

# fetch and expand test files, bind mounted into container below
curl -L -X GET "https://download.mozilla.org/?product=firefox-nightly-latest-ssl&os=linux64&lang=en-US" -o firefox.tar.bz2
tar xjf firefox.tar.bz2

waysock=1; sudo docker run --rm -ti \
  -e XDG_RUNTIME_DIR=/tmp -e XDG_SESSION_TYPE=wayland -e WAYLAND_DISPLAY=wayland-${waysock} -e GDK_BACKEND=wayland \
  -v $PWD/waysocket/wayland-${waysock}:/tmp/wayland-${waysock} --user=0: \
  --volume ${PWD}/firefox/:/var/tmp/firefox/ --env MOZ_ENABLE_WAYLAND=1 \
  tester \
  /var/tmp/firefox/firefox about:support

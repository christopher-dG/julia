#!/usr/bin/env bash

set -e

if [[ "$1" == "docker" ]]; then
  yum -y install bzip2 gcc make tar

  PREFIX="$HOME/layer"

  build_and_install() {
    base="$(python -c "import re; print(re.match('(\D+)-', '$1').group(1))")"
    curl "https://gnupg.org/ftp/gcrypt/$base/$1.tar.bz2" | tar jxf -
    cd "$1"
    ./configure \
      --prefix="$PREFIX" \
      --with-ksba-prefix="$PREFIX" \
      --with-libassuan-prefix="$PREFIX" \
      --with-libgcrypt-prefix="$PREFIX" \
      --with-libgpg-error-prefix="$PREFIX" \
      --with-npth-prefix="$PREFIX"
    make -j "$(nproc)"
    make install
    cd ..
  }

  cd /tmp
  for pkg in npth-1.6 libgpg-error-1.39 libgcrypt-1.8.7 libksba-1.5.0 libassuan-2.5.4 gnupg-2.2.24; do
    build_and_install "$pkg"
  done
else
  docker run -t --rm -v "$(pwd):/root" amazonlinux:2 "/root/$0" docker
fi

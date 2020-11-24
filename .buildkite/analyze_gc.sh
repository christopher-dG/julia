#!/usr/bin/env bash

set -eux

"$MAKE" -C deps install-llvm install-libuv install-utf8proc install-unwind
"$MAKE" -C test/clangsa
"$MAKE" -C src analyzegc

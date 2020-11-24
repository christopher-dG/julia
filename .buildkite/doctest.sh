#!/usr/bin/env bash

set -eux

"$MAKE" release
"$MAKE" -C doc JULIA_PRECOMPILE=0 doctest=true
"$MAKE" -C doc JULIA_PRECOMPILE=0 html

eval "$($MAKE print-JULIA_VERSION)"
eval "$($MAKE print-JULIA_COMMIT)"

docs="julia-docs-$JULIA_VERSION-$JULIA_COMMIT.tar.gz"
tar -zcf "$docs" doc/_build/html
buildkite-agent meta-data set docs "$docs"
buildkite-agent artifact upload "$docs"

rm -rf /tmp/srcccache
"$MAKE" JULIA_PRECOMPILE=0 USE_BINARYBUILDER=0 light-source-dist
light="julia-${JULIA_VERSION}_${JULIA_COMMIT}.tar.gz"
buildkite-agent meta-data set light-source-dist "$light"
buildkite-agent artifact upload "$light"

rm -rf /tmp/srcccache
"$MAKE" JULIA_PRECOMPILE=0 USE_BINARYBUILDER=0 full-source-dist
full="julia-${JULIA_VERSION}_${JULIA_COMMIT}-full.tar.gz"
buildkite-agent meta-data set full-source-dist "$full"
buildkite-agent artifact upload "$full"

rm -rf /tmp/srcccache
"$MAKE" JULIA_PRECOMPILE=0 USE_BINARYBUILDER=1 full-source-dist
full_bb="julia-${JULIA_VERSION}_${JULIA_COMMIT}-full.tar.gz"
mv "$full" "bb-$full"
buildkite-agent meta-data set full-source-dist-bb "bb-$full"
buildkite-agent artifact upload "bb-$full"

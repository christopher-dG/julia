#!/usr/bin/env bash

set -eux

source "$(dirname $0)/promote_utils.sh"

if [[ "$IS_MASTER" != "true" ]]; then
  echo "This step should not be running on pull requests, or on branches other than master"
  # exit 1
fi

docs="$(buildkite-agent meta-data get docs)"
buildkite-agent artifact download "$docs" .
aws s3 cp "$docs" "s3://$STAGING_BUCKET/docs/$(date +%s)-$RANDOM.tar.gz"

light="$(buildkite-agent meta-data get light-source-dist)"
full="$(buildkite-agent meta-data get full-source-dist)"
full_bb="$(buildkite-agent meta-data get full-source-dist-bb)"

buildkite-agent artifact download "$light" .
buildkite-agent artifact download "$full" .
buildkite-agent artifact download "$full_bb" .

version="$(echo $light | cut -d- -f2)"
commit="$(echo $light | cut -d- -f3)"
metadata="version=$version,commit=$commit"
aws s3 cp "$light" "s3://$STAGING_BUCKET/src/$(date +%s)-$RANDOM.tar.gz" \
    --metadata "srcdist=light,version=$version,commit=$commit"
aws s3 cp "$full" "s3://$STAGING_BUCKET/src/$(date +%s)-$RANDOM.tar.gz" \
    --metadata "srcdist=full,version=$version,commit=$commit"
aws s3 cp "$full_bb" "s3://$STAGING_BUCKET/src/$(date +%s)-$RANDOM.tar.gz" \
    --metadata "srcdist=full+bb,version=$version,commit=$commit"

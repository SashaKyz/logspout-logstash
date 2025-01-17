#!/usr/bin/env bash

# High-level summary:
#   1. Fetch all gliderlabs/logspout (parent image) tags.
#   2. Build the project with each parent image, and give the same tag.
#   3. Push all tags.


HUB_REPO="${DOCKER_REPO:-cwds/logspout-logstash}"

function main {
  TAGS=$(curl -s --retry 5 "https://hub.docker.com/v2/repositories/gliderlabs/logspout/tags/?page_size=5" \
      | jq -r '.results|.[].name')
  echo "Upstream tags: $TAGS"

  for t in ${TAGS}; do
    # Fetch the relevant build.sh
    if [ $t == 'latest' ] ; then
       curl -s --retry 3 -O "https://raw.githubusercontent.com/gliderlabs/logspout/release/custom/build.sh"
    else
       curl -s --retry 3 -O "https://raw.githubusercontent.com/gliderlabs/logspout/$t/custom/build.sh"
    fi

    docker build -t $HUB_REPO:$t --build-arg UPSTREAM_VERSION=$t .
    if [ $? -ne 0 ] ; then
      echo "ERROR: failed to build $t"
    fi
    rm -f build.sh
  done

  for t in ${TAGS}; do
    docker push $HUB_REPO:$t
    if [ $? -ne 0 ] ; then
      echo "ERROR: failed to push $t"
    fi
  done
}

main

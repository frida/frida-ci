#!/bin/bash

name=$1
if [[ -z $name || ! -d ./$name ]]; then
  echo "Usage: $0 <image>" > /dev/stderr
  exit 1
fi

set -ex

tag=fridadotre/$name

docker build -t $tag -f $name/Dockerfile $name/
docker push $tag

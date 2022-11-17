#!/bin/bash

module=$1

if [ -z "$module" ]; then
  path="**"
else
  path="${module}/**"
fi

docker run -v $PWD:/workdir ghcr.io/igorshubovych/markdownlint-cli:latest "website/docs/${path}/*.md" 

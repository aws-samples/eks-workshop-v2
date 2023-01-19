#!/bin/bash

set -e

bash /prepare.sh

node /app/dist/cli.js test "$@" /content 

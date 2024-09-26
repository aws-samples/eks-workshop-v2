#!/bin/bash

set -e

logmessage "Deleting AIML resources..."

kubectl delete namespace aiml --ignore-not-found

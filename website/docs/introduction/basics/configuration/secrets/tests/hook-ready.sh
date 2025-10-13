#!/usr/bin/env bash
set -Eeuo pipefail

before() {
    echo "Waiting for catalog pod to be ready..."
    kubectl wait --for=condition=ready pod/catalog-pod -n catalog --timeout=300s
}

after() {
    echo "noop"
}

"$@"
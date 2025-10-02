set -e

before() {
  echo "noop"
}

after() {
  response=$(kubectl run curl-test --image=curlimages/curl \
    --rm -iq --restart=Never -- \
    curl http://mistral.vllm:8080/v1/completions \
    -H "Content-Type: application/json" \
    -d '{"model": "/models/mistral-7b-v0.3","prompt": "The names of the colors in the rainbow are: ","max_tokens": 100,"temperature": 0}')

  tokens=$(echo $response | jq '.usage.completion_tokens')

  if [[ $tokens -lt 1 ]]; then
    >&2 echo "No completion tokens"
    >&2 echo $response
    exit 1
  fi
}

"$@"

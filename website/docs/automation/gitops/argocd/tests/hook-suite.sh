set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  rm -rf ~/environment/argocd/*

  git -C ~/environment/argocd commit . -m 'Reset'
  git -C ~/environment/argocd push
}

"$@"

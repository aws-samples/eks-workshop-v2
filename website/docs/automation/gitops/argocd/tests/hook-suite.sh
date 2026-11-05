set -e

before() {
  # Nothing to do yet. The capability only exists once the module's index page has
  # run prepare-environment, which happens after this hook, so the Argo CD CLI is
  # set up by the hook on that command instead (hook-argocd-cli.sh).
  echo "noop"
}

after() {
  prepare-environment
}

"$@"

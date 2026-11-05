set -Eeuo pipefail

hook_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

before() {
  echo "noop"
}

# Runs after `prepare-environment automation/gitops/argocd` on the module's index
# page. That command is what enables the capability when it is not already there
# (CI, or a participant's own account), so this is the earliest point at which the
# endpoint can be read and a token minted. At an AWS-run event the capability is
# pre-provisioned and this works the same way.
after() {
  # Ask the capability for its own endpoint. serverUrl comes back with an https://
  # prefix and the Argo CD CLI wants a bare host.
  local server
  server=$(aws eks describe-capability \
    --cluster-name "$EKS_CLUSTER_NAME" \
    --capability-name argocd \
    --query 'capability.configuration.argoCd.serverUrl' \
    --output text)
  server="${server#https://}"

  # The capability authenticates only through IAM Identity Center, so there is no
  # password to post to /api/v1/session. A participant generates a token in the
  # Argo CD UI; a test cannot, so drive the same sign-in headlessly.
  #
  # Deliberately not tolerant of failure: without a token every argocd command in
  # the lab would run unauthenticated and fail with confusing downstream errors.
  local token
  token=$(python3 "$hook_dir/argocd-token.py" --server "$server")

  # A hook runs as its own `bash` process, so anything it exports is gone when it
  # exits and never reaches the page commands. Write the token into the Argo CD
  # CLI's own config instead: every later `argocd` command reads it from there, with
  # nothing needed in the environment.
  #
  # The lab later exports ARGOCD_SERVER and ARGOCD_OPTS itself. The CLI lets
  # ARGOCD_SERVER override the server named here, and still takes the token from
  # this context when ARGOCD_AUTH_TOKEN is unset, which it is in the tests because
  # the line that pastes it is not run.
  #
  # Same directory lookup as the CLI: ARGOCD_CONFIG_DIR, then an existing
  # ~/.argocd, then $XDG_CONFIG_HOME/argocd or ~/.config/argocd.
  local config_dir
  if [[ -n "${ARGOCD_CONFIG_DIR:-}" ]]; then
    config_dir="$ARGOCD_CONFIG_DIR"
  elif [[ -d "$HOME/.argocd" ]]; then
    config_dir="$HOME/.argocd"
  else
    config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/argocd"
  fi

  mkdir -p "$config_dir"
  # The CLI refuses a config file that others can read, and it holds a token.
  (
    umask 077
    cat >"$config_dir/config" <<EOF
contexts:
- name: ${server}
  server: ${server}
  user: ${server}
current-context: ${server}
servers:
- grpc-web: true
  server: ${server}
users:
- auth-token: ${token}
  name: ${server}
EOF
  )
  chmod 600 "$config_dir/config"

  echo "Argo CD CLI configured for ${server}"
}

"$@"

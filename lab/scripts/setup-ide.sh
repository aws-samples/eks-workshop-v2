#!/bin/bash

set -e

cat << EOT > /home/ec2-user/.banner-text

                                          Welcome to

███████╗██╗  ██╗███████╗    ██╗    ██╗ ██████╗ ██████╗ ██╗  ██╗███████╗██╗  ██╗ ██████╗ ██████╗ 
██╔════╝██║ ██╔╝██╔════╝    ██║    ██║██╔═══██╗██╔══██╗██║ ██╔╝██╔════╝██║  ██║██╔═══██╗██╔══██╗
█████╗  █████╔╝ ███████╗    ██║ █╗ ██║██║   ██║██████╔╝█████╔╝ ███████╗███████║██║   ██║██████╔╝
██╔══╝  ██╔═██╗ ╚════██║    ██║███╗██║██║   ██║██╔══██╗██╔═██╗ ╚════██║██╔══██║██║   ██║██╔═══╝ 
███████╗██║  ██╗███████║    ╚███╔███╔╝╚██████╔╝██║  ██║██║  ██╗███████║██║  ██║╚██████╔╝██║     
╚══════╝╚═╝  ╚═╝╚══════╝     ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝ 

                      Hands-on labs for Amazon Elastic Kubernetes Service

EOT

# Workshop content URL: snapshot branches (snapshot-<name>) are published at
# snapshots.eksworkshop.com/<name>/, everything else uses the main site.
if [[ "${REPOSITORY_REF}" == snapshot-* ]]; then
  WORKSHOP_URL="https://snapshots.eksworkshop.com/${REPOSITORY_REF#snapshot-}/"
else
  WORKSHOP_URL="https://www.eksworkshop.com/"
fi

# Console login link only applies to Workshop Studio events (WS is the
# workshop id, empty for self-paced). The link is the same for every region.
CONSOLE_URL=""
if [ -n "${WS}" ]; then
  CONSOLE_URL="https://catalog.us-east-1.prod.workshops.aws/event/account-login"
fi

mkdir -p ~/.bashrc.d
cat << EOT > ~/.bashrc.d/workshop-links.bash
export WORKSHOP_URL="${WORKSHOP_URL}"
export CONSOLE_URL="${CONSOLE_URL}"
EOT
cat << 'EOT' >> ~/.bashrc.d/workshop-links.bash

workshop() {
  # Colors only when writing to a terminal, so piped output stays plain.
  local label="" url="" rule="" dim="" reset=""
  if [ -t 1 ]; then
    label=$'\e[1;38;5;208m' # bold, EKS orange
    url=$'\e[4;96m'         # underlined bright cyan
    rule=$'\e[38;5;208m'
    dim=$'\e[2m'
    reset=$'\e[0m'
  fi
  local line="────────────────────────────────────────────────────────────────────────────"

  echo "${rule}${line}${reset}"
  echo "  ${label}Workshop URL:${reset}      ${url}${WORKSHOP_URL}${reset}"
  if [ -n "$CONSOLE_URL" ]; then
    echo "  ${label}Login to console:${reset}  ${url}${CONSOLE_URL}${reset}"
  else
    echo "  ${label}AWS console:${reset}       Sign in to the account you deployed the workshop in."
  fi
  echo "${rule}${line}${reset}"
  echo "  ${dim}Type 'workshop' at any time to show these links again.${reset}"
}

# Print the links when an IDE terminal opens: interactive VS Code shells only
# (not scripts or bash -c), and not again in shells nested inside a terminal.
# banner.bash sorts first, so the first terminal shows the banner, then these.
if [[ $- == *i* ]] && [ "$TERM_PROGRAM" = "vscode" ] && [ -z "$WORKSHOP_LINKS_SHOWN" ]; then
  export WORKSHOP_LINKS_SHOWN=1
  workshop
  echo ""
fi
EOT

mkdir -p ~/.local/share/code-server/User
touch ~/.local/share/code-server/User/settings.json
cat << EOF > ~/.local/share/code-server/User/settings.json
{
  "extensions.autoUpdate": false,
  "extensions.autoCheckUpdates": false,
  "security.workspace.trust.enabled": false,
  "task.allowAutomaticTasks": "on",
  "telemetry.telemetryLevel": "off",
  "workbench.startupEditor": "terminal",
  "workbench.secondarySideBar.defaultVisibility": "hidden",
  "chat.disableAIFeatures": true,
  "terminal.integrated.environmentChangesRelaunch": false
}
EOF

# code-server options. The IDE CloudFormation writes config.yaml, runs this
# script, then restarts code-server, so appending here takes effect without a
# template change. Skipped when config.yaml does not exist (make ide).
#  - disable-update-check: hide the "code-server vX has been released" toast.
#  - link-protection-trusted-domains: open workshop and console links without
#    the "Do you want code-server to open the external website?" prompt.
CODE_SERVER_CONFIG=~/.config/code-server/config.yaml
if [ -f "$CODE_SERVER_CONFIG" ] && ! grep -q '^link-protection-trusted-domains:' "$CODE_SERVER_CONFIG"; then
  cat << EOF >> "$CODE_SERVER_CONFIG"
disable-update-check: true
link-protection-trusted-domains:
  - https://*.eksworkshop.com
  - https://eksworkshop.com
  - https://catalog.us-east-1.prod.workshops.aws
  - https://console.aws.amazon.com
  - https://*.console.aws.amazon.com
EOF
fi

mkdir -p ~/environment/.vscode
cat << EOF > ~/environment/.vscode/settings.json
{
  "files.exclude": {
    "**/.*": true
  }
}
EOF

echo '{ "query": { "folder": "/home/ec2-user/environment" } }' > ~/.local/share/code-server/coder.json

code-server --install-extension redhat.vscode-yaml --force || true
code-server --install-extension ms-kubernetes-tools.vscode-kubernetes-tools --force || true
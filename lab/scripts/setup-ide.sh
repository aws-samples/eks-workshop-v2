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

workshop() {
  echo "Workshop URL:     \$WORKSHOP_URL"
  if [ -n "\$CONSOLE_URL" ]; then
    echo "Login to console: \$CONSOLE_URL"
  else
    echo "Sign in to the AWS console of the account you deployed the workshop in."
  fi
}

# Print the links when an IDE terminal opens: interactive VS Code shells only
# (not scripts or bash -c), and not again in shells nested inside a terminal.
# banner.bash sorts first, so the first terminal shows the banner, then these.
if [[ \$- == *i* ]] && [ "\$TERM_PROGRAM" = "vscode" ] && [ -z "\$WORKSHOP_LINKS_SHOWN" ]; then
  export WORKSHOP_LINKS_SHOWN=1
  workshop
  echo "(Type 'workshop' at any time to show these links again.)"
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
  "chat.disableAIFeatures": true
}
EOF

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
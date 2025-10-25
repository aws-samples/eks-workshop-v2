#!/bin/bash

set -e

bash /entrypoint.sh

cat << EOT > /tmp/wrapper.sh
#!/bin/bash

set -e

export -f prepare-environment

node /app/dist/cli.js test "\$@" /content 
EOT

bash -l /tmp/wrapper.sh $@

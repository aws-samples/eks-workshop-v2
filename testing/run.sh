#!/bin/bash

set -e

bash /entrypoint.sh

# When running tests, manifests are volume-mounted from the host.
# Clear REPOSITORY_REF so reset-environment skips git clone.
echo 'export REPOSITORY_REF=""' > /home/ec2-user/.bashrc.d/repository.bash

cat << EOT > /tmp/wrapper.sh
#!/bin/bash

set -e

export -f prepare-environment

node /app/dist/cli.js test "\$@" /content 
EOT

bash -l /tmp/wrapper.sh $@

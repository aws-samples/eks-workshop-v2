#!/bin/bash

set -e

bash /entrypoint.sh

# When running tests, manifests are volume-mounted from the host.
# Clear REPOSITORY_REF so reset-environment skips git clone.
echo 'export REPOSITORY_REF=""' > /home/ec2-user/.bashrc.d/repository.bash

# CI runners share egress IPs, so anonymous chart pulls from public.ecr.aws
# (helm install oci://public.ecr.aws/...) hit the per-IP data limit and fail
# with "429 toomanyrequests: Data limit exceeded". Log helm in with the test
# role so pulls count against the account quota instead. Best effort: a role
# without ecr-public:GetAuthorizationToken falls back to anonymous pulls.
if aws ecr-public get-login-password --region us-east-1 2>/dev/null \
    | helm registry login --username AWS --password-stdin public.ecr.aws > /dev/null 2>&1; then
  echo "Logged in to public.ecr.aws for helm chart pulls"
else
  echo "Warning: could not log in to public.ecr.aws, helm chart pulls will be anonymous"
fi

cat << EOT > /tmp/wrapper.sh
#!/bin/bash

set -e

export -f prepare-environment

node /app/dist/cli.js test "\$@" /content 
EOT

bash -l /tmp/wrapper.sh $@

environment=${environment:-""}

if [ -z "$environment" ]; then
  export EKS_CLUSTER_NAME="eks-workshop"
  export EKS_CLUSTER_AUTO_NAME="eks-workshop-auto"
else
  export EKS_CLUSTER_NAME="eks-workshop-${environment}"
  export EKS_CLUSTER_AUTO_NAME="eks-workshop-${environment}-auto"
fi

AWS_REGION=${AWS_REGION:-""}

if [ -z "$AWS_REGION" ]; then
  echo "Warning: Defaulting region to us-west-2"

  export AWS_REGION="us-west-2"
fi

SKIP_CREDENTIALS=${SKIP_CREDENTIALS:-""}
USE_CURRENT_USER=${USE_CURRENT_USER:-""}
AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID:-""} # We check the access key

# If no credentials are configured, attempt to retrieve them from EC2 IMDSv2
if [ -z "$AWS_ACCESS_KEY_ID" ] && [ -z "$SKIP_CREDENTIALS" ]; then
  IMDS_TOKEN=$(curl -s --connect-timeout 2 -X PUT "http://169.254.169.254/latest/api/token" \
    -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" 2>/dev/null) || true

  if [ -n "$IMDS_TOKEN" ]; then
    IMDS_ROLE=$(curl -s --connect-timeout 2 \
      -H "X-aws-ec2-metadata-token: $IMDS_TOKEN" \
      "http://169.254.169.254/latest/meta-data/iam/security-credentials/" 2>/dev/null) || true

    if [ -n "$IMDS_ROLE" ]; then
      IMDS_CREDS=$(curl -s --connect-timeout 2 \
        -H "X-aws-ec2-metadata-token: $IMDS_TOKEN" \
        "http://169.254.169.254/latest/meta-data/iam/security-credentials/${IMDS_ROLE}" 2>/dev/null) || true

      if [ -n "$IMDS_CREDS" ]; then
        export AWS_ACCESS_KEY_ID=$(echo "$IMDS_CREDS" | grep -o '"AccessKeyId" *: *"[^"]*"' | cut -d'"' -f4)
        export AWS_SECRET_ACCESS_KEY=$(echo "$IMDS_CREDS" | grep -o '"SecretAccessKey" *: *"[^"]*"' | cut -d'"' -f4)
        export AWS_SESSION_TOKEN=$(echo "$IMDS_CREDS" | grep -o '"Token" *: *"[^"]*"' | cut -d'"' -f4)
        echo "Retrieved credentials from EC2 IMDSv2 (role: ${IMDS_ROLE})"
      fi
    fi
  fi
fi

if [ -z "$SKIP_CREDENTIALS" ]; then
  ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

  IDE_ROLE_NAME="${EKS_CLUSTER_NAME}-ide-role"
  IDE_ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${IDE_ROLE_NAME}"
fi

# Set RESOURCE_CODEBUILD_ROLE_ARN if not already provided (e.g. by Workshop Studio)
if [ -z "${RESOURCE_CODEBUILD_ROLE_ARN:-}" ]; then
  export RESOURCE_CODEBUILD_ROLE_ARN="${IDE_ROLE_ARN:-}"
fi

export DOCKER_CLI_HINTS="false"
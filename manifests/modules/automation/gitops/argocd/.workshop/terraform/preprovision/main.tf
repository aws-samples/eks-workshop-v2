# IAM Identity Center provisioning for the Amazon EKS Capability for Argo CD.
#
# This lives in a `preprovision` directory on purpose. Those directories are only
# ever applied by `hack/pre-provision-resources.sh`, which is only invoked by the
# AWS Workshop Studio provisioning pipeline (`make pre-provision`). Unlike the
# convention in other labs, the lab module deliberately does NOT declare a
# `module "preprovision"` block, so `prepare-environment` never applies this
# directory: it is copied into the Terraform working directory and then ignored,
# because Terraform only loads directories reachable from a `source` argument.
#
# That asymmetry is the whole point. Enabling IAM Identity Center is an
# account-wide, single-instance and effectively irreversible change, and the user
# below is written into a directory that may hold real identities. We only do
# either where the account is disposable, which means Workshop Studio events. On
# every other entry point the lab discovers what it needs and refuses to start if
# it isn't there.
#
# The same line decides how we treat MFA. If this script creates the instance, it
# relaxes MFA enforcement so participants can sign in with just a username and
# password, because nothing else will ever use that directory. If it finds an
# instance already there, it adopts it untouched: another workload's sign-in policy
# is not ours to weaken, even to make a demo smoother.

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  # Instances created here carry this name. The destroy provisioner only removes an
  # instance with it, so an instance we adopted is never torn down.
  idc_instance_name = "eks-workshop"

  idc_user_name = "eks-workshop"

  # Identity Center does not require the sign-in name to be an email address, so the
  # user name stays short and memorable for participants to type. The directory still
  # wants a primary email, and nothing ever delivers to it, so use the address range
  # RFC 2606 reserves for documentation.
  idc_user_email = "eks-workshop@example.com"
}

resource "null_resource" "idc_instance" {
  triggers = {
    region        = data.aws_region.current.id
    instance_name = local.idc_instance_name
  }

  provisioner "local-exec" {
    command = <<-EOF
      set -e
      REGION="${data.aws_region.current.id}"
      NAME="${local.idc_instance_name}"
      ACCOUNT="${data.aws_caller_identity.current.account_id}"

      IDC_JSON=$(aws sso-admin list-instances --region $REGION --output json)
      COUNT=$(echo "$IDC_JSON" | jq '.Instances | length')

      if [ "$COUNT" != "0" ]; then
        IDC_ARN=$(echo "$IDC_JSON" | jq -r '.Instances[0].InstanceArn')
        IDC_STATUS=$(echo "$IDC_JSON" | jq -r '.Instances[0].Status')
        IDC_OWNER=$(echo "$IDC_JSON" | jq -r '.Instances[0].OwnerAccountId // empty')
        echo "Found existing IAM Identity Center instance $IDC_ARN (status $IDC_STATUS, owner $IDC_OWNER)"

        # An instance owned by another account is an organization instance shared
        # from the management account. Creating a workshop user in it would write
        # into a directory that may hold real identities, so refuse rather than
        # adopt it.
        if [ -n "$IDC_OWNER" ] && [ "$IDC_OWNER" != "$ACCOUNT" ]; then
          echo "ERROR: this IAM Identity Center instance is an organization instance owned by $IDC_OWNER." >&2
          echo "       Refusing to provision a workshop user into a directory this account does not own." >&2
          exit 1
        fi

        # Adopting an instance somebody else set up. Use it as-is: its sign-in
        # policy is not ours to relax, so MFA settings are left untouched and
        # participants follow whatever this instance already enforces.
        if [ "$IDC_STATUS" = "ACTIVE" ]; then
          echo "Reusing existing account instance $IDC_ARN, leaving its MFA settings unchanged"
          exit 0
        fi

        if [ "$IDC_STATUS" = "CREATE_FAILED" ]; then
          echo "Removing CREATE_FAILED instance $IDC_ARN..."
          aws sso-admin delete-instance --instance-arn "$IDC_ARN" --region $REGION
          for i in $(seq 1 60); do
            COUNT=$(aws sso-admin list-instances --region $REGION --output json | jq '.Instances | length')
            [ "$COUNT" = "0" ] && break
            sleep 5
          done
        fi
      fi

      echo "Creating IAM Identity Center instance $NAME..."
      IDC_ARN=$(aws sso-admin create-instance --name "$NAME" \
        --region $REGION --output json | jq -r '.InstanceArn')
      echo "IAM Identity Center ARN: $IDC_ARN"

      ACTIVE=false
      for i in $(seq 1 60); do
        STATUS=$(aws sso-admin describe-instance --instance-arn "$IDC_ARN" \
          --region $REGION --output json | jq -r '.Status // "UNKNOWN"')
        echo "  [$i] IAM Identity Center status: $STATUS"
        if [ "$STATUS" = "ACTIVE" ]; then
          ACTIVE=true
          break
        fi
        if [ "$STATUS" = "CREATE_FAILED" ]; then
          echo "IAM Identity Center CREATE_FAILED" >&2
          exit 1
        fi
        sleep 5
      done

      if [ "$ACTIVE" != "true" ]; then
        echo "Timeout waiting for IAM Identity Center to become ACTIVE" >&2
        exit 1
      fi

      # Reached only when this script created the instance above, so the directory
      # is one we just made in a disposable event account and nothing else uses it.
      # A brand new instance asks users to register an MFA device on first sign-in,
      # and that prompt replaces the forced password change the lab depends on.
      #
      # Best-effort on purpose: if this fails the event still provisions and
      # participants are merely asked to enroll an MFA device.
      if ! python3 -c 'import boto3' 2>/dev/null; then
        echo "Installing boto3 to configure MFA enforcement..."
        # The retry covers PEP 668: on a GitHub Actions runner the system Python is
        # marked externally managed and refuses a plain install. Installing into it
        # anyway is fine because every host that reaches this is disposable.
        python3 -m pip install --quiet --disable-pip-version-check boto3 \
          || python3 -m pip install --quiet --disable-pip-version-check \
               --break-system-packages boto3 \
          || true
      fi

      python3 "${abspath("${path.module}/disable-mfa.py")}" --region "$REGION" \
        || echo "WARNING: could not disable MFA enforcement on the instance we created; participants may be asked to register an MFA device"
    EOF
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOF
      REGION="${self.triggers.region}"
      NAME="${self.triggers.instance_name}"
      IDC_ARN=$(aws sso-admin list-instances --region $REGION --output json \
        | jq -r --arg name "$NAME" '.Instances[] | select(.Name==$name) | .InstanceArn // empty' | head -1)
      if [ -n "$IDC_ARN" ]; then
        echo "Deleting IAM Identity Center instance $IDC_ARN..."
        aws sso-admin delete-instance --instance-arn "$IDC_ARN" --region $REGION 2>/dev/null || true
      else
        echo "No IAM Identity Center instance named $NAME, nothing to delete"
      fi
    EOF
  }
}

# Deferred to apply time: the instance, and therefore its identity store, does not
# exist until the provisioner above has run.
data "aws_ssoadmin_instances" "main" {
  depends_on = [null_resource.idc_instance]
}

# The Argo CD administrator participants sign in as. Created here rather than in
# the lab module so that the only Identity Center directory we ever write to is
# one this account owns, and in practice one we just created.
resource "aws_identitystore_user" "argocd_admin" {
  identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]

  user_name    = local.idc_user_name
  display_name = "ArgoCD Workshop Admin"

  name {
    given_name  = "ArgoCD"
    family_name = "Admin"
  }

  emails {
    value   = local.idc_user_email
    primary = true
  }
}

# There is no API that sets an IAM Identity Center password. identitystore:CreateUser
# makes a user with no password, and nothing in the CLI, any SDK, CloudFormation or
# Terraform can give it one. The only supported route is the one a human
# administrator takes: mint a one-time password, sign in with it, and complete the
# password change Identity Center forces on that first sign-in.
#
# `activate-user.py` drives exactly that in a browser. Everything below exists to
# hand it a password and to publish the result.

# Secrets Manager generates the password, through GetRandomPassword. This is only a
# candidate: it is used the first time the user is activated and is otherwise
# ignored, because the script prefers whatever is already stored in the secret.
data "aws_secretsmanager_random_password" "argocd_admin" {
  password_length            = 16
  require_each_included_type = true

  # Identity Center rejects a password with no symbol, so punctuation stays enabled.
  # These particular characters are excluded because they break quoting when the
  # value is passed through a shell or embedded in JSON on its way to the browser.
  exclude_characters = "\"@/\\'`"
}

resource "aws_secretsmanager_secret" "argocd_admin" {
  # checkov:skip=CKV_AWS_149:A customer-managed key would add a KMS key per event
  # account without a security gain. The lab's IDE role has to read this secret, so
  # it would need kms:Decrypt as well, leaving the same principals with the same
  # access. The default aws/secretsmanager key already keeps it encrypted at rest.
  # checkov:skip=CKV2_AWS_57:Rotation would be actively harmful. Nothing propagates a
  # rotated value back to the IAM Identity Center user, so a rotation would replace a
  # working credential with one that cannot sign in. The secret lives and dies with a
  # single event.
  name        = "${var.eks_cluster_id}-argocd-idc"
  description = "Argo CD IAM Identity Center sign-in for the EKS workshop"

  # Events are torn down and recreated in the same account, and a secret in the
  # default 30-day recovery window would collide with the next run by name.
  recovery_window_in_days = 0

  tags = var.tags
}

# Deliberately no `aws_secretsmanager_secret_version` here. The activation script
# writes the value itself, and only after it has signed in with the password in a
# fresh browser session. That way the secret either holds a credential that is known
# to work or holds nothing at all, instead of a plausible-looking password that was
# never actually set on the user.
# Enabling the capability takes around ten minutes, so it happens here, while the
# event is still being provisioned, instead of on the participant's clock during
# `prepare-environment`. Keeping it in this state rather than the lab's also means
# moving between labs no longer tears it down and rebuilds it.
#
# Independent of the activation below, so Terraform runs the two concurrently and
# the browser sign-in overlaps the Argo CD rollout.
module "capability" {
  source = "./capability"

  eks_cluster_id   = var.eks_cluster_id
  idc_instance_arn = tolist(data.aws_ssoadmin_instances.main.arns)[0]
  idc_user_id      = aws_identitystore_user.argocd_admin.user_id
  tags             = var.tags
}

resource "null_resource" "idc_user_activation" {
  depends_on = [
    # The user has to exist, and MFA enforcement has to already be relaxed:
    # with MFA enforced the portal shows a device-registration prompt instead of
    # the password change page, and activation cannot complete.
    null_resource.idc_instance,
    aws_identitystore_user.argocd_admin,
    aws_secretsmanager_secret.argocd_admin,
  ]

  triggers = {
    region    = data.aws_region.current.id
    user_name = local.idc_user_name
    secret_id = aws_secretsmanager_secret.argocd_admin.id
    script    = filemd5("${path.module}/activate-user.py")
  }

  provisioner "local-exec" {
    # Not best-effort, unlike the MFA step. A failure here means participants have
    # no way to sign in, so it should break the event build while somebody is still
    # watching, rather than surface as a broken lab hours later.
    command = <<-EOF
      set -e

      if ! python3 -c 'import playwright' 2>/dev/null; then
        echo "Installing Playwright..."
        # The retry covers PEP 668: on a GitHub Actions runner the system Python is
        # marked externally managed and refuses a plain install. Installing into it
        # anyway is fine because every host that reaches this is disposable.
        python3 -m pip install --quiet --disable-pip-version-check playwright boto3 \
          || python3 -m pip install --quiet --disable-pip-version-check \
               --break-system-packages playwright boto3
      fi

      # Pulls the system libraries Chromium needs. Both places this runs are Debian
      # based -- the Workshop Studio build image and the GitHub Actions runner -- so
      # this is apt-based.
      python3 -m playwright install --with-deps chromium

      ARGOCD_IDC_CANDIDATE_PASSWORD='${data.aws_secretsmanager_random_password.argocd_admin.random_password}' \
      python3 "${abspath("${path.module}/activate-user.py")}" \
        --region "${data.aws_region.current.id}" \
        --user-name "${local.idc_user_name}" \
        --secret-id "${aws_secretsmanager_secret.argocd_admin.id}" \
        --screenshot-dir /tmp/idc-activation
    EOF
  }
}

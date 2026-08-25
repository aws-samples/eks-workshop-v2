# IAM Identity Center for every lab that needs it.
#
# Identity Center is the one thing a lab cannot provision for itself. There is a
# single instance per account per Region, enabling it is effectively irreversible,
# and the directory it creates may end up holding real identities. So exactly one
# place creates it, and that place is only ever reached by the Workshop Studio
# provisioning pipeline.
#
# That "only ever reached" is structural rather than a flag. This directory lives
# outside `manifests/modules`, so `hack/pre-provision-resources.sh` does not pick it
# up as a module, and no lab root has a `source` pointing at it. Terraform only
# loads what a `source` reaches, so lab code cannot apply this even by accident.
# `pre-provision-resources.sh` stages it explicitly, and only when a lab asks for
# it, so an event whose labs do not need Identity Center never gets an instance.
#
# Labs consume this the same way in both directions: they never take its outputs,
# they discover the instance, the group and the secret through data sources and a
# naming convention. That keeps a lab's Terraform identical whether Identity Center
# was pre-provisioned here or created by hand for a self-service run, and it is why
# there is no wiring between this module and the lab modules staged alongside it.
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  # Instances created here carry this name, and the destroy provisioner only removes
  # an instance with it, so an instance we adopted is never torn down. It is not
  # per-environment on purpose: there is only one instance per account per Region,
  # so a second environment in the same account adopts this one rather than getting
  # its own.
  idc_instance_name = "eks-workshop"

  # Everything we write *into* the directory is per-environment, because the
  # instance is not. `eks_cluster_id` is `eks-workshop` for an event and
  # `eks-workshop-<environment>` everywhere else, so two environments sharing an
  # account get their own user, group and secret instead of colliding on a name.
  #
  # This removes the user-name collision between concurrent runs. It does not remove
  # the race on creating the instance itself: two environments that both find no
  # instance will both try to create one and one of them will lose. Pre-provisioning
  # runs that share an account still need serialising for that reason.
  idc_user_name  = var.eks_cluster_id
  idc_group_name = "${var.eks_cluster_id}-argocd-admins"

  # Identity Center does not require the sign-in name to be an email address, so the
  # user name stays short and memorable for participants to type. The directory still
  # wants a primary email, and nothing ever delivers to it, so use the address range
  # RFC 2606 reserves for documentation.
  idc_user_email = "${var.eks_cluster_id}@example.com"
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
    when = destroy
    # Terraform destroys the user and group before this runs, so an empty directory
    # here means this environment was the only thing using the instance. If anything
    # is left, another environment in the same account still needs it and the
    # instance stays: per-environment user names make that overlap possible, and
    # deleting a shared instance would break the environment that is still running.
    command = <<-EOF
      REGION="${self.triggers.region}"
      NAME="${self.triggers.instance_name}"
      IDC_ARN=$(aws sso-admin list-instances --region $REGION --output json \
        | jq -r --arg name "$NAME" '.Instances[] | select(.Name==$name) | .InstanceArn // empty' | head -1)

      if [ -z "$IDC_ARN" ]; then
        echo "No IAM Identity Center instance named $NAME, nothing to delete"
        exit 0
      fi

      STORE_ID=$(aws sso-admin list-instances --region $REGION --output json \
        | jq -r --arg name "$NAME" '.Instances[] | select(.Name==$name) | .IdentityStoreId // empty' | head -1)

      if [ -n "$STORE_ID" ]; then
        REMAINING=$(aws identitystore list-users --identity-store-id "$STORE_ID" \
          --region $REGION --output json 2>/dev/null | jq '.Users | length' || echo 0)
        if [ "$REMAINING" != "0" ]; then
          echo "Leaving IAM Identity Center instance $IDC_ARN in place: $REMAINING user(s) still in its directory"
          exit 0
        fi
      fi

      echo "Deleting IAM Identity Center instance $IDC_ARN..."
      aws sso-admin delete-instance --instance-arn "$IDC_ARN" --region $REGION 2>/dev/null || true
    EOF
  }
}

# Deferred to apply time: the instance, and therefore its identity store, does not
# exist until the provisioner above has run.
data "aws_ssoadmin_instances" "main" {
  depends_on = [null_resource.idc_instance]
}

locals {
  identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]
}

# The administrator participants sign in as.
resource "aws_identitystore_user" "argocd_admin" {
  identity_store_id = local.identity_store_id

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

# Capabilities map this group to the Argo CD ADMIN role rather than mapping the user
# directly. The indirection costs one resource and means a second lab, or a second
# cluster in the same event, grants access by adding a member instead of editing an
# `rbac_role_mapping` it does not own.
#
# Membership is what makes a single activated user enough. Activation is a browser
# sign-in per user (see activate-user.py), so a per-lab or per-cluster user would
# mean a browser round-trip each. One user in one group keeps that cost flat however
# many capabilities map the group.
resource "aws_identitystore_group" "argocd_admins" {
  identity_store_id = local.identity_store_id
  display_name      = local.idc_group_name
  description       = "Argo CD administrators for ${var.eks_cluster_id} (EKS Workshop)"
}

resource "aws_identitystore_group_membership" "argocd_admin" {
  identity_store_id = local.identity_store_id
  group_id          = aws_identitystore_group.argocd_admins.group_id
  member_id         = aws_identitystore_user.argocd_admin.user_id
}

# There is no API that sets an IAM Identity Center password. identitystore:CreateUser
# makes a user with no password, and nothing in the CLI, any SDK, CloudFormation or
# Terraform can give it one. The only supported route is the one a human
# administrator takes: mint a one-time password, sign in with it, and complete the
# password change Identity Center forces on that first sign-in.
#
# `activate-user.py` drives exactly that in a browser. Everything below exists to
# hand it a password and to publish the result.

resource "aws_secretsmanager_secret" "argocd_admin" {
  # checkov:skip=CKV_AWS_149:A customer-managed key would add a KMS key per event
  # account without a security gain. The lab's IDE role has to read this secret, so
  # it would need kms:Decrypt as well, leaving the same principals with the same
  # access. The default aws/secretsmanager key already keeps it encrypted at rest.
  # checkov:skip=CKV2_AWS_57:Rotation would be actively harmful. Nothing propagates a
  # rotated value back to the IAM Identity Center user, so a rotation would replace a
  # working credential with one that cannot sign in. The secret lives and dies with a
  # single event.

  # Labs find this by convention rather than by output, so the name is part of this
  # module's interface: `${eks_cluster_id}-argocd-idc`.
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
    # Deliberately no password anywhere in this provisioner. Terraform echoes a
    # provisioner's command string verbatim, so interpolating one here put a working
    # credential in plain text in the build log of every event. Moving it to an
    # `environment` block hides it but makes Terraform suppress the provisioner's whole
    # output, and those log lines are all anyone gets when activation fails.
    #
    # CodeBuild cannot mask it either: it only masks strings it injected itself from
    # Secrets Manager or Parameter Store, matched against the exact stored value, and
    # this password does not exist until the script mints it.
    #
    # So the script mints it (see generate_password), making the same
    # GetRandomPassword call this module used to make.
    #
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

      python3 "${abspath("${path.module}/activate-user.py")}" \
        --region "${data.aws_region.current.id}" \
        --user-name "${local.idc_user_name}" \
        --secret-id "${aws_secretsmanager_secret.argocd_admin.id}" \
        --screenshot-dir /tmp/idc-activation
    EOF
  }
}

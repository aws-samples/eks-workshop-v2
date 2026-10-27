#!/usr/bin/env python3
"""Disable MFA enforcement on the account's IAM Identity Center instance.

Workshop participants sign in to Argo CD with a username and password issued by
IAM Identity Center. By default a new instance asks users to register an MFA
device the first time they sign in, which blocks the forced password change and
requires an authenticator app participants may not have.

There is no public API, CloudFormation resource or Terraform resource for this
setting. This calls the same internal control-plane endpoint the IAM Identity
Center console uses, signed with SigV4 against the ``sso`` service:

    POST https://sso.<region>.amazonaws.com/control/
    X-Amz-Target: SWBService.UpdateSsoConfiguration

The ``mfaMode: DISABLED`` / ``noMfaSignInBehavior: ALLOWED_WITH_ENROLLMENT``
pairing is what the console shows as "Prompt users for MFA: Never". It reads
oddly but is what the console sends -- do not "correct" it.

This endpoint is undocumented and AWS can change or remove it without notice. It
is called best-effort: any failure exits non-zero with a diagnostic and the
caller downgrades that to a warning, so provisioning still succeeds and
participants are merely asked to enroll an MFA device.
"""

import argparse
import json
import sys
import urllib.error
import urllib.request


def fail(message):
    print(f"disable-mfa: {message}", file=sys.stderr)
    sys.exit(1)


def main():
    parser = argparse.ArgumentParser(description="Disable IAM Identity Center MFA enforcement")
    parser.add_argument("--region", required=True, help="Region the IAM Identity Center instance lives in")
    args = parser.parse_args()

    try:
        import boto3
        from botocore.auth import SigV4Auth
        from botocore.awsrequest import AWSRequest
    except ImportError as exc:
        fail(f"boto3/botocore not available ({exc})")

    session = boto3.Session(region_name=args.region)

    # CodeBuild does not expose credentials as environment variables, so read the
    # resolved credentials off the session rather than the environment.
    credentials = session.get_credentials()
    if credentials is None:
        fail("no AWS credentials available")
    frozen_credentials = credentials.get_frozen_credentials()

    instances = session.client("sso-admin").list_instances().get("Instances", [])
    if not instances:
        fail("no IAM Identity Center instance found")

    instance_arn = instances[0]["InstanceArn"]
    print(f"disable-mfa: disabling MFA enforcement on {instance_arn}")

    body = json.dumps(
        {
            "instanceArn": instance_arn,
            "configurationType": "APP_AUTHENTICATION_CONFIGURATION",
            "ssoConfiguration": {
                "mfaMode": "DISABLED",
                "noMfaSignInBehavior": "ALLOWED_WITH_ENROLLMENT",
                "allowedMfaTypes": ["TOTP", "WEBAUTHN"],
            },
        }
    ).encode("utf-8")

    url = f"https://sso.{args.region}.amazonaws.com/control/"
    signed = AWSRequest(
        method="POST",
        url=url,
        data=body,
        headers={
            "Content-Type": "application/x-amz-json-1.1",
            "X-Amz-Target": "SWBService.UpdateSsoConfiguration",
        },
    )
    SigV4Auth(frozen_credentials, "sso", args.region).add_auth(signed)

    try:
        with urllib.request.urlopen(
            urllib.request.Request(url, data=body, headers=dict(signed.headers), method="POST"),
            timeout=30,
        ) as response:
            print(f"disable-mfa: HTTP {response.status}, MFA enforcement disabled")
    except urllib.error.HTTPError as exc:
        fail(f"HTTP {exc.code} from UpdateSsoConfiguration: {exc.read().decode('utf-8', 'replace')}")
    except urllib.error.URLError as exc:
        fail(f"could not reach the IAM Identity Center control endpoint: {exc.reason}")


if __name__ == "__main__":
    main()

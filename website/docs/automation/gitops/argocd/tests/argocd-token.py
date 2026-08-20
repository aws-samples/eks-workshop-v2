#!/usr/bin/env python3
"""Mint an Argo CD API token so the automated test suite can run the Argo CD CLI.

The EKS Capability for Argo CD authenticates only through IAM Identity Center. Its
`/api/v1/settings` advertises an OIDC issuer and no Dex or local accounts, and
posting to `/api/v1/session` is refused with "no credentials supplied" because there
is no password account to authenticate against. No EKS API issues a token either:
the service only exposes Create, Delete, Describe, List and Update for capabilities.

So the only way in is the one a participant takes, which the lab documents: sign in
and generate a token. A participant does that by clicking through the UI. A test
cannot click, so this drives the same sign-in headlessly and reads the session token
Argo CD hands back.

This exists purely so the CLI steps in the lab are covered by tests rather than
merely documented. Nothing participants run depends on it, and it is never part of
event provisioning.

The Identity Center sign-in form is fiddly enough that it is worth having in exactly
one place, so the sign-in itself is reused from the pre-provisioning activation
script rather than reimplemented here.
"""

import argparse
import contextlib
import importlib.util
import os
import sys

# Mounted into the test container at /eks-workshop/manifests.
DEFAULT_ACTIVATE_USER_PY = (
    "/eks-workshop/manifests/modules/automation/gitops/argocd"
    "/.workshop/terraform/preprovision/activate-user.py"
)

# Argo CD stores the JWT it issues after a successful OIDC sign-in under this name.
TOKEN_COOKIE = "argocd.token"

# The OIDC bounce back from Identity Center involves several redirects.
REDIRECT_TIMEOUT_MS = 60000


def load_activation_module(path):
    """Import activate-user.py by path, since its directory is not a package."""
    if not os.path.exists(path):
        raise SystemExit(
            f"argocd-token: cannot find the activation helper at {path}.\n"
            "               Set ACTIVATE_USER_PY if the manifests are mounted "
            "somewhere else."
        )
    spec = importlib.util.spec_from_file_location("idc_activation", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def read_password(region, secret_id):
    """Read the password pre-provisioning proved works, from Secrets Manager."""
    import json

    import boto3

    client = boto3.Session(region_name=region).client("secretsmanager")
    try:
        payload = client.get_secret_value(SecretId=secret_id)["SecretString"]
    except Exception as exc:  # noqa: BLE001 - message matters more than the type
        raise SystemExit(
            f"argocd-token: could not read {secret_id}: {exc}\n"
            "               The Argo CD tests need the Identity Center password "
            "that event pre-provisioning stores there."
        ) from exc
    password = json.loads(payload).get("password", "")
    if not password:
        raise SystemExit(f"argocd-token: {secret_id} holds no password")
    return password


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--server",
        required=True,
        help="Argo CD endpoint, with or without the https:// prefix",
    )
    parser.add_argument("--region", default=os.environ.get("AWS_REGION", ""))
    parser.add_argument("--user-name", default="eks-workshop")
    parser.add_argument(
        "--secret-id",
        default=f"{os.environ.get('EKS_CLUSTER_NAME', 'eks-workshop')}-argocd-idc",
    )
    parser.add_argument("--screenshot-dir", default="/tmp/argocd-token")
    args = parser.parse_args()

    host = args.server.removeprefix("https://").removeprefix("http://").rstrip("/")
    password = read_password(args.region, args.secret_id)

    activation = load_activation_module(
        os.environ.get("ACTIVATE_USER_PY", DEFAULT_ACTIVATE_USER_PY)
    )

    from playwright.sync_api import sync_playwright

    with sync_playwright() as playwright:
        driver = activation.Driver(playwright, args.screenshot_dir, headless=True)
        try:
            # The activation helper logs its progress to stdout, which here is
            # reserved for the token, so send anything it prints to stderr instead.
            # Those lines are still worth keeping: they are the only diagnostics if a
            # sign-in starts failing in CI.
            with contextlib.redirect_stdout(sys.stderr):
                # Argo CD bounces this straight to Identity Center, which presents
                # the same sign-in form the activation script already drives.
                ok, page, context = activation.portal_sign_in(
                    driver, f"https://{host}/auth/login", args.user_name, password
                )

                # Submitting the password leaves the browser on the Identity Center
                # domain. The session is only issued once the OIDC redirect lands
                # back on Argo CD, so wait for that rather than reading cookies from
                # a page that has not returned yet.
                if ok:
                    try:
                        page.wait_for_url(
                            f"https://{host}/**", timeout=REDIRECT_TIMEOUT_MS
                        )
                    except Exception:  # noqa: BLE001 - reported by the check below
                        driver.where(page, "argocd-redirect-did-not-land")
            if not ok:
                driver.where(page, "argocd-sign-in-failed")
                raise SystemExit(
                    "argocd-token: the Identity Center sign-in did not complete, so "
                    "no token was issued"
                )

            token = next(
                (
                    cookie["value"]
                    for cookie in context.cookies(f"https://{host}")
                    if cookie["name"] == TOKEN_COOKIE
                ),
                "",
            )
            if not token:
                driver.where(page, "argocd-no-token-cookie")
                raise SystemExit(
                    f"argocd-token: signed in but Argo CD set no {TOKEN_COOKIE} "
                    "cookie, so there is no token to use"
                )

            # stdout carries the token and nothing else, so callers can capture it
            # directly. Everything above logs to stderr.
            print(token)
        finally:
            driver.close()


if __name__ == "__main__":
    sys.exit(main())

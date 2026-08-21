#!/usr/bin/env python3
"""Give an IAM Identity Center user a working password, and publish it.

No supported API sets an Identity Center password. ``identitystore:CreateUser``
creates a user without one, and nothing in the AWS CLI, any SDK, CloudFormation or
Terraform can set one. Two steps are therefore needed:

1. Reset the password to a one-time password. Done with a signed request to the
   internal control plane the admin console uses, see mint_one_time_password.
2. Sign in to the AWS access portal with that OTP and complete the password change
   Identity Center forces on a first sign-in. This needs a browser: the change is
   only accepted during a genuine sign-in, and PasswordMode offers no way to set a
   permanent password directly.

Step 1 used to drive the admin console too, which meant a cookie banner, four
similar copy buttons and a clipboard read. It is now one HTTP call.

Ordering requirements handled by the caller: the user must exist, and MFA
enforcement must already be relaxed. With MFA enforced the portal shows a
device-registration prompt instead of the password change page and this cannot
complete.

Idempotent. If the password already stored in Secrets Manager signs in, this
exits immediately, so re-running ``terraform apply`` does not try the OTP path
against an already-activated user.

The failure mode to worry about is silent success: reporting done while only the
OTP works. Every step is therefore asserted rather than assumed, and the final
password is proven by signing in again in a fresh browser context before it is
written to Secrets Manager.

Step 2 drives the portal sign-in UI and *will* break when AWS changes it. Every
decision point logs the current URL and the visible page text, missed selectors
dump the controls that were actually present, and screenshots are written to
--screenshot-dir. Screenshots do not survive a Workshop Studio build container, so
the log is written to be sufficient on its own.
"""

import argparse
import json
import os
import sys
import urllib.error
import urllib.request

STEP_TIMEOUT_MS = 30000


def log(message):
    print(f"activate-user: {message}", flush=True)


class ActivationError(RuntimeError):
    pass


class Driver:
    """Playwright wrapper carrying the diagnostics this flow needs."""

    def __init__(self, playwright, screenshot_dir, headless=True):
        self.playwright = playwright
        self.screenshot_dir = screenshot_dir
        self.headless = headless
        self.browser = playwright.chromium.launch(headless=headless)
        self._shot_index = 0
        if screenshot_dir:
            os.makedirs(screenshot_dir, exist_ok=True)

    def new_context(self):
        context = self.browser.new_context(
            viewport={"width": 1600, "height": 1200},
        )
        context.set_default_timeout(STEP_TIMEOUT_MS)
        return context

    def shot(self, page, name):
        if not self.screenshot_dir:
            return
        self._shot_index += 1
        path = os.path.join(self.screenshot_dir, f"{self._shot_index:02d}-{name}.png")
        try:
            page.screenshot(path=path, full_page=True)
            log(f"screenshot {path}")
        except Exception as exc:  # diagnostics must never mask the real failure
            log(f"could not capture screenshot {name}: {exc}")

    def where(self, page, label):
        """Log where we are. Called at every decision point."""
        try:
            text = " ".join((page.locator("body").inner_text() or "").split())
        except Exception:
            text = "<unreadable>"
        log(f"[{label}] url={page.url}")
        # Generous budget on purpose. Screenshots land in the build container's /tmp
        # and are unrecoverable once a Workshop Studio build ends, so the log has to
        # be sufficient on its own.
        log(f"[{label}] text={text[:1200]}")
        self.shot(page, label)

    def dump_controls(self, page, label):
        """Called when a selector misses, to show what was actually on the page."""
        log(f"[{label}] selector missed, dumping visible controls")
        for selector in ("button", "input", "a[role='button']", "[role='radio']"):
            try:
                items = page.locator(selector)
                for i in range(min(items.count(), 25)):
                    item = items.nth(i)
                    if not item.is_visible():
                        continue
                    attrs = {
                        a: item.get_attribute(a)
                        for a in ("id", "name", "type", "value", "aria-label", "placeholder")
                    }
                    attrs = {k: v for k, v in attrs.items() if v}
                    log(f"  {selector}[{i}] text={(item.inner_text() or '').strip()[:60]!r} {attrs}")
            except Exception as exc:
                log(f"  could not enumerate {selector}: {exc}")
        self.shot(page, f"{label}-miss")

    def close(self):
        try:
            self.browser.close()
        except Exception:
            pass


def frozen_credentials(session):
    """CodeBuild does not expose credentials as environment variables, so take them
    off the SDK session."""
    credentials = session.get_credentials()
    if credentials is None:
        raise ActivationError("no AWS credentials available")
    return credentials.get_frozen_credentials()


def mint_one_time_password(session, region, identity_store_id, user_id):
    """Reset the user's password to a one-time password and return it.

    No CLI, SDK, CloudFormation or Terraform operation resets an Identity Center
    password, so this signs a request to the SWBUPService control plane the admin
    console uses. Unsupported, and carries the same maintenance risk as
    disable-mfa.py beside it: if activation starts failing, look here first.

    Only a one-time password can be produced this way, which is why the portal
    sign-in below still needs a browser to set the permanent one.
    """
    from botocore.auth import SigV4Auth
    from botocore.awsrequest import AWSRequest

    host = f"identitystore.{region}.amazonaws.com"
    url = f"https://{host}/identitystore/"
    body = json.dumps({"IdentityStoreId": identity_store_id, "UserId": user_id,
                       "PasswordMode": "OTP"})

    # Host, X-Amz-Target and Content-Type are set before signing so they are covered
    # by SignedHeaders; the control plane rejects the request otherwise.
    request = AWSRequest(
        method="POST",
        url=url,
        data=body,
        headers={
            "Host": host,
            "X-Amz-Target": "SWBUPService.UpdatePassword",
            "Content-Type": "application/x-amz-json-1.1",
        },
    )
    SigV4Auth(frozen_credentials(session), "userpool", region).add_auth(request)

    log(f"resetting the password via {host} (SWBUPService.UpdatePassword)")
    encoded = body.encode("utf-8")
    http_request = urllib.request.Request(
        url, data=encoded, headers=dict(request.headers), method="POST"
    )
    try:
        with urllib.request.urlopen(http_request, timeout=30) as response:
            payload = json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", "replace")[:500]
        raise ActivationError(
            f"UpdatePassword returned HTTP {exc.code}: {detail}"
        ) from exc

    otp = payload.get("Password") or ""
    if not otp:
        raise ActivationError(
            f"UpdatePassword succeeded but returned no password: {sorted(payload)}"
        )

    log(f"minted a one-time password ({otp_fingerprint(otp)})")
    return otp


def resolve_user_id(session, identity_store_id, user_name):
    """Look up the user's ID, which UpdatePassword addresses it by."""
    identitystore = session.client("identitystore")
    try:
        response = identitystore.get_user_id(
            IdentityStoreId=identity_store_id,
            AlternateIdentifier={
                "UniqueAttribute": {
                    "AttributePath": "UserName",
                    "AttributeValue": user_name,
                }
            },
        )
    except identitystore.exceptions.ResourceNotFoundException as exc:
        raise ActivationError(
            f"IAM Identity Center user {user_name} does not exist"
        ) from exc
    return response["UserId"]


def portal_sign_in(driver, portal_url, user_name, password):
    """Attempt a portal sign-in. Returns (ok, page, context).

    The caller owns closing the context. When ok is False the page is left where it
    landed so the caller can decide whether that is a password change prompt, an MFA
    prompt or a genuine failure.
    """
    context = driver.new_context()
    page = context.new_page()
    page.goto(portal_url, wait_until="domcontentloaded")
    driver.where(page, "portal-loaded")

    # The portal asks for the username, then the password on a second step. Some
    # tenants render both at once, so treat the second step as optional.
    try:
        username_field = page.locator("input[type='text'], input[type='email']").first
        username_field.wait_for(state="visible", timeout=STEP_TIMEOUT_MS)
        username_field.fill(user_name)
        log(f"portal username step: {submit_form(page, 'Next', 'Continue', 'Sign in')}")
    except Exception as exc:
        driver.dump_controls(page, "portal-username")
        raise ActivationError("could not find the portal username field") from exc

    try:
        password_field = page.locator("input[type='password']").first
        password_field.wait_for(state="visible", timeout=STEP_TIMEOUT_MS)
    except Exception as exc:
        driver.where(page, "portal-no-password-field")
        driver.dump_controls(page, "portal-password")
        raise ActivationError("portal never presented a password field") from exc

    password_field.fill(password)
    log(f"portal password step: {submit_form(page, 'Sign in', 'Submit', 'Continue')}")
    page.wait_for_load_state("networkidle")

    # The submit is asynchronous, so networkidle can land before the next step
    # renders. Wait for the outcome instead. There are three, and all of them have to
    # be listed here: a signed-in page with no password field, the forced password
    # change, or an error. Waiting only for the field to disappear would time out on
    # every successful activation, because the change form is itself made of password
    # fields.
    try:
        page.wait_for_function(
            """() => {
                const pw = document.querySelectorAll("input[type='password']");
                // Signed straight in: the sign-in form is gone.
                if (pw.length === 0) return true;
                // Forced password change: a new/confirm pair replaced the single field.
                if (pw.length > 1) return true;
                if (/Set new password|Change password/.test(document.body.innerText)) {
                    return true;
                }
                // Rejected, or a policy hint the caller logs.
                return !!document.querySelector("[role='alert']");
            }""",
            timeout=STEP_TIMEOUT_MS,
        )
    except Exception:  # noqa: BLE001 - fall through to the dumps below
        log("portal did not settle after the password submit")

    driver.where(page, "portal-after-submit")

    alerts = form_alerts(page)
    if alerts:
        log(f"portal alerts: {alerts}")

    body = (page.locator("body").inner_text() or "")

    # A forced password change means the credential was accepted but is not yet the
    # long-term one, so this is not a successful sign-in.
    if is_password_change_page(page, body):
        return False, page, context

    if page.locator("input[type='password']").count() > 0:
        return False, page, context

    lowered = body.lower()
    if "incorrect" in lowered or "try again" in lowered or "not authorized" in lowered:
        return False, page, context

    return True, page, context


def submit_form(page, *labels):
    """Submit the current step, preferring a real button click over Enter.

    The portal renders its own "Sign in" button and does not reliably submit on
    Enter. When Enter is swallowed the page simply stays where it is with no error,
    which looks exactly like a rejected credential and sends debugging the wrong way.
    """
    for label in labels:
        button = page.locator(
            f"button[type='submit']:has-text('{label}'), button:has-text('{label}')"
        ).first
        try:
            if button.count() > 0 and button.is_visible() and button.is_enabled():
                button.click()
                return f"clicked {label!r}"
        except Exception as exc:  # noqa: BLE001 - fall through to the next candidate
            log(f"submit: {label!r} raised {exc}")
    page.keyboard.press("Enter")
    return "pressed Enter"


def form_alerts(page):
    """Inline validation text, which body inner_text does not always include.

    Without this a rejected credential and a form that never submitted look
    identical in the dumps.
    """
    messages = []
    for selector in ("[role='alert']", "[aria-live='assertive']", "[aria-live='polite']"):
        located = page.locator(selector)
        for i in range(min(located.count(), 5)):
            try:
                text = (located.nth(i).inner_text() or "").strip()
            except Exception:  # noqa: BLE001 - detached node
                continue
            if text and text not in messages:
                messages.append(text)
    return messages


def is_password_change_page(page, body=None):
    """The password form has no usable attributes: bare input[type=password] with
    external label elements. name*="new", placeholder*="New password" and
    autocomplete="new-password" all match nothing, so detect the page by its
    heading instead."""
    if body is None:
        body = page.locator("body").inner_text() or ""
    if "Set new password" in body or "Change password" in body:
        return True
    for text in ("Set new password", "Change password"):
        if page.locator(f":text('{text}')").count() > 0:
            return True
    return False


def otp_fingerprint(otp):
    """Describe an OTP without printing it.

    Enough to tell a real password apart from a username or a stray label in the
    logs, without putting the credential itself in a build log.
    """
    return (
        f"{len(otp)} chars"
        f", {sum(c.isupper() for c in otp)} upper"
        f", {sum(c.islower() for c in otp)} lower"
        f", {sum(c.isdigit() for c in otp)} digit"
        f", {sum(not c.isalnum() for c in otp)} symbol"
    )


def set_password_with_otp(driver, portal_url, user_name, otp, new_password):
    """Sign in with the OTP and complete the forced password change."""
    ok, page, context = portal_sign_in(driver, portal_url, user_name, otp)
    try:
        if ok:
            # Signing straight in means no password change was demanded, so the OTP
            # was treated as a long-term password. Nothing was set.
            raise ActivationError(
                "the portal did not force a password change after the OTP sign-in"
            )

        body = page.locator("body").inner_text() or ""
        if not is_password_change_page(page, body):
            driver.where(page, "portal-unexpected-after-otp")
            if "multi-factor" in body.lower() or "MFA" in body:
                raise ActivationError(
                    "the portal is asking for MFA registration instead of a password "
                    "change; MFA enforcement was not relaxed before activation"
                )
            raise ActivationError("the portal did not present the password change form")

        # Bare inputs with external labels, so fill positionally: first is the new
        # password, second is the confirmation.
        # New password and Confirm new password render a beat apart, and this page
        # always carries a password-policy hint in an alert region, so any wait keyed
        # on "an alert appeared" returns while the form is still half-built. Wait for
        # both inputs specifically.
        try:
            page.wait_for_function(
                "() => Array.from(document.querySelectorAll(\"input[type='password']\"))"
                ".filter(i => i.offsetParent !== null).length >= 2",
                timeout=STEP_TIMEOUT_MS,
            )
        except Exception:  # noqa: BLE001 - the count below reports it properly
            log("the password change form never exposed a second input")

        fields = page.locator("input[type='password']")
        visible = [fields.nth(i) for i in range(fields.count()) if fields.nth(i).is_visible()]
        log(f"password change form has {len(visible)} visible password inputs")
        if len(visible) < 2:
            driver.dump_controls(page, "portal-password-form")
            raise ActivationError("the password change form did not expose two inputs")

        visible[0].fill(new_password)
        visible[1].fill(new_password)
        log(f"password change step: {submit_form(page, 'Set new password', 'Change password', 'Confirm', 'Submit')}")
        page.wait_for_load_state("networkidle")
        page.wait_for_timeout(2000)
        driver.where(page, "portal-after-password-change")

        alerts = form_alerts(page)
        if alerts:
            log(f"password change alerts: {alerts}")

        # A successful click proves nothing. If the password violates the Identity
        # Center policy the page stays put with a validation error, so require the
        # form to be gone.
        if is_password_change_page(page):
            raise ActivationError(
                "the password change form is still displayed, so the new password was "
                "rejected; check the Identity Center password policy"
            )
    finally:
        context.close()


def verify_password(driver, portal_url, user_name, password):
    """Sign in from a clean context. This is the only check that proves the password
    works independently of the OTP; without it the whole flow can report success
    while being broken."""
    ok, _, context = portal_sign_in(driver, portal_url, user_name, password)
    context.close()
    return ok


def read_stored_password(client, secret_id):
    try:
        response = client.get_secret_value(SecretId=secret_id)
    except client.exceptions.ResourceNotFoundException:
        return None
    except Exception as exc:
        # A secret with no version raises here too, which is the normal first run.
        log(f"no usable stored password yet ({type(exc).__name__})")
        return None
    try:
        return json.loads(response["SecretString"]).get("password") or None
    except (KeyError, ValueError):
        return None


def generate_password(secrets):
    """Mint the candidate password here rather than receiving it from Terraform.

    Terraform echoes a provisioner's command string verbatim as it runs it, so a
    password interpolated into that command ends up in plain text in the
    pre-provisioning build log. Moving it into the provisioner's `environment` block
    hides it, but Terraform then suppresses the provisioner's entire output, which
    takes every log line below with it -- exactly what someone diagnosing a failed
    activation has to work from.

    Generating it in here keeps the password out of the log and keeps the log. It is
    the same GetRandomPassword call Terraform's `aws_secretsmanager_random_password`
    data source made, with the same constraints, so the result is interchangeable.
    """
    return secrets.get_random_password(
        PasswordLength=16,
        RequireEachIncludedType=True,
        # Identity Center rejects a password with no symbol, so punctuation stays
        # enabled. These particular characters are excluded because they break quoting
        # when the value is passed through a shell or embedded in JSON on its way to
        # the browser, and because the stored value is later rendered into
        # single-quoted `export` lines for the IDE shell.
        ExcludeCharacters="\"@/\\'`",
    )["RandomPassword"]


def main():
    parser = argparse.ArgumentParser(description="Activate an IAM Identity Center user")
    parser.add_argument("--region", required=True)
    parser.add_argument("--user-name", required=True)
    parser.add_argument("--secret-id", required=True)
    parser.add_argument("--screenshot-dir", default="")
    parser.add_argument(
        "--headed",
        action="store_true",
        help="Run with a visible browser, for debugging the console flow locally",
    )
    args = parser.parse_args()

    import boto3
    from playwright.sync_api import sync_playwright

    session = boto3.Session(region_name=args.region)
    secrets = session.client("secretsmanager")

    instances = session.client("sso-admin").list_instances().get("Instances", [])
    if not instances:
        raise ActivationError("no IAM Identity Center instance found")
    instance = instances[0]
    identity_store_id = instance["IdentityStoreId"]

    portal_url = f"https://{identity_store_id}.awsapps.com/start"
    log(f"portal {portal_url}")

    stored_password = read_stored_password(secrets, args.secret_id)
    # ARGOCD_IDC_CANDIDATE_PASSWORD is an override for the local harness
    # (hack/activate-idc-user.sh). Nothing sets it during pre-provisioning: the
    # password is minted below instead, so that it never passes through Terraform.
    candidate = os.environ.get("ARGOCD_IDC_CANDIDATE_PASSWORD", "")
    # Prefer the stored password so a re-apply keeps the credential participants may
    # already be holding, and only fall back to a freshly generated one.
    if not stored_password and not candidate:
        candidate = generate_password(secrets)
    target_password = stored_password or candidate
    if not target_password:
        raise ActivationError("no password available and none could be generated")

    with sync_playwright() as playwright:
        driver = Driver(playwright, args.screenshot_dir, headless=not args.headed)
        try:
            if stored_password:
                log("a password is already stored, checking whether it still signs in")
                if verify_password(driver, portal_url, args.user_name, stored_password):
                    log("stored password works, nothing to do")
                    return
                log("stored password no longer works, re-activating with it")

            user_id = resolve_user_id(session, identity_store_id, args.user_name)
            otp = mint_one_time_password(
                session, args.region, identity_store_id, user_id
            )

            set_password_with_otp(driver, portal_url, args.user_name, otp, target_password)

            log("verifying the new password in a fresh browser session")
            if not verify_password(driver, portal_url, args.user_name, target_password):
                raise ActivationError(
                    "the new password does not sign in from a clean session, so only "
                    "the one-time password is usable"
                )
        finally:
            driver.close()

    # Written only now, so the secret either holds a credential proven to work or
    # holds nothing at all.
    secrets.put_secret_value(
        SecretId=args.secret_id,
        SecretString=json.dumps({"username": args.user_name, "password": target_password}),
    )
    log(f"password verified and stored in {args.secret_id}")


if __name__ == "__main__":
    try:
        main()
    except ActivationError as exc:
        print(f"activate-user: ERROR {exc}", file=sys.stderr)
        sys.exit(1)

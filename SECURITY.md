# Security Policy

## Supported versions

Security fixes are provided for the latest released version of BarTranslate.
Please update to the newest release before reporting an issue.

## Reporting a vulnerability

If you believe you have found a security or privacy vulnerability in
BarTranslate, please report it privately — **do not** open a public issue.

- Email **trinhnv1205@gmail.com** with the subject line `BarTranslate Security`.
- Include a description of the issue, the version affected, and clear steps to
  reproduce (a proof of concept is appreciated).

We aim to acknowledge reports within **5 business days** and to provide a
remediation timeline after triage. Please give us a reasonable window to ship a
fix before any public disclosure.

## Scope

In scope:

- The BarTranslate macOS app and its handling of local data (translation
  history, preferences, license/entitlement state).
- The offline license validation and Pro entitlement logic.

Out of scope:

- Vulnerabilities in third-party services the app embeds (e.g. Google
  Translate). Report those to the respective vendor.
- The deliberately offline, best-effort nature of license-key validation. It is
  designed to deter casual sharing, not to be tamper-proof; a production
  deployment should additionally verify a signed StoreKit receipt or a server
  signature.

## Data handling

BarTranslate stores data locally (and, if enabled, in your private iCloud
account). It contains no third-party analytics or tracking. See
[PRIVACY.md](PRIVACY.md) for details.

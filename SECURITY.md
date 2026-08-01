# Security Policy

## Supported versions

Security fixes are applied to the latest released version of DailyHQ.

## Reporting a vulnerability

Please do not open a public issue for a suspected vulnerability or expose credentials in screenshots, logs, commits, or pull requests.

Use GitHub's **Security → Report a vulnerability** option for this repository. Include the affected version, reproduction steps, potential impact, and any suggested mitigation. A maintainer will acknowledge the report and coordinate disclosure through the private report.

## Firebase configuration

Firebase client configuration and API keys identify a client application; they are not administrative credentials. Security depends on Firebase Authentication, restrictive Firestore rules, API restrictions, and appropriate project configuration.

Never commit Firebase Admin SDK service-account JSON, private keys, passwords, signing keys, or CI secrets. If any such credential is exposed, revoke or rotate it immediately and remove it from repository history where appropriate.

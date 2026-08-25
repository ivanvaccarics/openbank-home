# Terms of Use for openbank-home

Last updated: August 25, 2026

## Scope

These terms apply to the private openbank-home deployment registered with
Enable Banking. The deployment is a self-hosted personal finance application
intended solely for its operator's personal and non-commercial use. It is not a
service offered to the public.

The source code is separately distributed under the repository's
[MIT License](LICENSE). These terms govern use of the private deployment, not
the rights granted under that software license.

## Permitted use

The deployment may be used only by its operator to retrieve and review
information from bank accounts owned by that operator. Access must not be
provided to third parties, used for business or professional purposes, or used
to retrieve information from accounts that the operator is not authorized to
access.

Use of bank connectivity is also subject to the terms and authorization flows
of Enable Banking and the selected financial institutions. The operator must
keep credentials secure and comply with the restrictions applicable to an
Enable Banking Production application in restricted mode.

## No financial service or advice

openbank-home is not a bank, financial institution, payment service, accounting
service or financial adviser. It only imports and displays account information.
It does not initiate payments or make financial decisions.

Balances, transactions and other information may be delayed, incomplete,
duplicated or inaccurate. The operator must verify important information with
the relevant financial institution and must not rely on openbank-home as the
sole source for financial, tax, accounting or legal decisions.

## Availability

The deployment and its integrations are provided on an "as is" and "as
available" basis. Availability is not guaranteed. Bank APIs, Strong Customer
Authentication, consents, Enable Banking, Tailscale, network access and the
self-hosted server may change or become unavailable independently.

## Security and operator responsibilities

The operator is responsible for securing the host, tailnet, Actual Budget
account, Enable Banking credentials, encryption passwords and backups. The
operator must promptly revoke and replace credentials suspected of compromise
and must not commit financial data or secrets to the public repository.

## Data and consent management

The operator is responsible for obtaining and maintaining valid bank consents,
reviewing imported data, and deleting local data and backups when no longer
needed. Bank access can be revoked through the relevant bank or Enable Banking.

Personal data is handled as described in the
[openbank-home Privacy Notice](PRIVACY.md).

## Termination

Use may be stopped at any time by disconnecting linked accounts, revoking bank
consents, deleting the Enable Banking application and removing the local
deployment. Access must stop immediately if it would violate applicable law,
Enable Banking's terms or a financial institution's terms.

## Changes

These terms may be updated when the deployment or its integrations change. The
current version is published in this repository with its last-updated date.
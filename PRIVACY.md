# Privacy Notice for openbank-home

Last updated: August 25, 2026

## Scope

openbank-home is a private, self-hosted personal finance application used by its
operator for personal and non-commercial purposes. It combines Actual Budget
with Enable Banking to retrieve and display information from bank accounts owned
by the operator.

This notice applies to the operator's private deployment of openbank-home. The
public source code repository does not collect or store banking data.

## Data controller

The operator of the private openbank-home deployment is the data controller for
information stored in that deployment. The reference deployment is maintained
by Ivan Vaccari. Contact is available through the
[maintainer's GitHub profile](https://github.com/ivanvaccarics). Security or
privacy concerns that should not be public can be reported through a
[private security advisory](https://github.com/ivanvaccarics/openbank-home/security/advisories/new).

The data protection email entered in the Enable Banking application registration
is the primary contact for matters related to that registered application.

## Data processed

Depending on the information supplied by the selected bank, the application may
process:

- Bank and account identifiers, including account names and IBANs
- Account balances and currencies
- Booked and pending transactions
- Transaction dates, amounts, descriptions and counterparties
- Enable Banking consent, session and account identifiers
- Credentials and tokens required to maintain the bank connection

The application does not initiate payments. Enable Banking access is limited to
account information services.

## Purpose and legal basis

The data is processed solely to let the operator retrieve, store, categorise and
review information from the operator's own bank accounts. Processing is based on
the operator's explicit request and consent during the bank authorization flow.

The application is not used for advertising, profiling, credit decisions,
marketing or the sale of personal data.

## Storage and recipients

Financial data is stored on infrastructure controlled by the operator. Access
to the application is restricted to the operator's private Tailscale network.

Data is transmitted through Enable Banking and the selected financial
institutions as required to provide account information. Those parties process
data under their own privacy notices and legal obligations. Data is not made
available to unrelated third parties, except where required by law.

Encrypted backups may be created by the operator. The public GitHub repository
contains configuration templates and documentation only; it must not contain
credentials, account identifiers, balances or transactions.

## Retention and deletion

Data is retained for as long as the operator keeps it in Actual Budget or its
backups. The operator can delete imported transactions, remove an account,
delete the local data store and backups, or revoke the bank consent through the
bank or Enable Banking.

Technical logs are retained only as needed to operate and troubleshoot the
private deployment and are subject to the operator's local log rotation policy.

## Security

The deployment uses private Tailscale access, HTTPS, restricted local service
bindings, protected API credentials and encrypted backups where configured. No
method of storage or transmission is completely secure, and the operator is
responsible for maintaining the host, credentials and backups.

## Data protection rights

Where applicable, data subjects may request access, correction, deletion,
restriction, portability or objection regarding their personal data. Because
the restricted deployment is intended solely for the operator's own accounts,
the operator is normally the only data subject. Any concern involving another
person's information should be raised using the contact methods above.

## Changes

This notice may be updated when the application's data processing changes. The
current version is published in this repository with its last-updated date.
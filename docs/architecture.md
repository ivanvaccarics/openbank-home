# Architecture

## Data flow

1. Actual server runs on your home host.
2. Actual initiates outbound HTTPS calls to Enable Banking.
3. Enable Banking mediates PSD2 institution APIs.
4. Your banks return account and transaction data to Enable Banking.
5. Actual stores synced state locally (`account.sqlite`, user files).
6. Client devices access Actual through Tailscale Serve over `https://<host>.ts.net`.

## Why a server-side component is required

Bank sync credentials and refresh flow must persist on a continuously available server process. A laptop-only occasional session is unreliable for unattended sync windows and consent lifecycle operations.

## Polling limits and no true real-time push

Retail PSD2 access is polling-based for this stack. There is generally no true push/webhook stream for immediate transaction delivery.

Operational implications:

- Respect institution polling limits (commonly 4 unattended calls/day)
- Expect delays between card activity and visibility
- Plan periodic sync, not live streaming

## Pending vs booked lifecycle

Transactions can move through two states:

- **Pending**: authorization seen early, amount can still change
- **Booked**: settled final posting from institution

Temporary overlap can occur; automation and reconciliation should account for this transition.

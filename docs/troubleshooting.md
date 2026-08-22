# Troubleshooting

## Consent expired

Symptoms:

- Sync failures after a period of normal operation
- Bank authorization errors in Actual

Action:

- Re-authenticate account consent in Actual
- Track next expiry with `scripts/check-consents.sh`

## PSD2 rate limits

Many institutions allow around 4 unattended calls/day per account.

If you poll too often, requests may be throttled or denied temporarily. Reduce sync frequency and retry later.

## Duplicate pending/booked transactions

Card flows can appear as:

1. Pending authorization
2. Final booked transaction (amount/date may differ)

Short overlap can look like duplicates. Wait for booking before manual cleanup rules.

## Callback mismatch

If consent fails immediately after auth redirect:

- Confirm redirect URL in Enable Banking exactly matches Actual config
- Ensure format is `https://<host>.ts.net/enablebanking/auth_callback`
- Check for trailing slash or hostname mismatch

## Certificate / Serve failures

Checks:

- `tailscale status` is healthy
- Node is logged into the expected tailnet
- Serve is configured in background mode
- Local Actual port is listening on loopback

Re-apply with `./scripts/tailscale-serve.sh`.

## Healthcheck failures in container

If `docker compose ps` shows unhealthy:

1. Inspect logs: `docker compose logs --tail=200 actual`
2. Confirm disk space and write access for `data/actual`
3. Confirm container image/tag pull completed
4. Restart service: `docker compose restart actual`

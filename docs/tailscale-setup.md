# Tailscale setup

## 1) Install and connect

Install Tailscale on your server and run:

```bash
tailscale up
tailscale status
```

If authentication is required, open the URL printed by `tailscale up` and
approve the host. Confirm the node appears in your tailnet admin console.

## 2) MagicDNS and HTTPS certificates

Enable MagicDNS in the tailnet settings. Find the node's fully qualified DNS
name in the admin console or inspect the `Self.DNSName` field from:

```bash
tailscale status --json
```

The result normally resembles `<host>.<tailnet>.ts.net`. Remove any trailing
dot when setting `TS_HOSTNAME` in `.env`.

`tailscale serve` provisions and renews HTTPS certificates automatically for that name.

## 3) Serve Actual privately

Run:

```bash
./scripts/tailscale-serve.sh
tailscale serve status
```

This configures:

- `tailscale serve --bg --https=443`
- Backend: `http://127.0.0.1:<actual-port>`

Traffic stays private to the tailnet. The backend must already be running on
the configured `ACTUAL_PORT`.

## 4) Mobile setup

Install Tailscale on your phone, sign in to the same tailnet, then open
`https://<TS_HOSTNAME>`. Verify that Actual loads without a certificate warning
before using this origin in an OAuth or Open Banking redirect URL.

## 5) Split tunnelling

If you only want tailnet traffic in VPN, configure client split tunnelling / exit-node preferences according to your platform defaults.

## 6) Serve vs Funnel (critical)

- **Serve**: private to your tailnet (required here)
- **Funnel**: public internet exposure (must never be used for this stack)

If you run Headscale instead of Tailscale SaaS, ensure equivalent private routing and HTTPS termination behavior before exposing Actual.

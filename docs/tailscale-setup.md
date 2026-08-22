# Tailscale setup

## 1) Install and connect

Install Tailscale on your server and run:

```bash
tailscale up
```

Confirm the node appears in your tailnet admin console.

## 2) MagicDNS and HTTPS certificates

Enable MagicDNS in tailnet settings so each node gets a stable `<host>.ts.net` name.

`tailscale serve` provisions and renews HTTPS certificates automatically for that name.

## 3) Serve Actual privately

Run:

```bash
./scripts/tailscale-serve.sh
```

This configures:

- `tailscale serve --bg --https=443`
- Backend: `http://127.0.0.1:<actual-port>`

Traffic stays tailnet-private.

## 4) Mobile setup

Install Tailscale on your phone, sign in to the same tailnet, then open `https://<host>.ts.net`.

## 5) Split tunnelling

If you only want tailnet traffic in VPN, configure client split tunnelling / exit-node preferences according to your platform defaults.

## 6) Serve vs Funnel (critical)

- **Serve**: private to your tailnet (required here)
- **Funnel**: public internet exposure (must never be used for this stack)

## 7) Headscale note

If you run Headscale instead of Tailscale SaaS, ensure equivalent private routing and HTTPS termination behavior before exposing Actual.

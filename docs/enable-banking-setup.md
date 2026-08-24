# Enable Banking setup for Actual Budget

## 1) Go / no-go check first

Before creating anything, verify your target institutions are available in Enable Banking: <https://enablebanking.com/open-banking-apis>

- BPER
- isybank / Intesa Sanpaolo
- Revolut

If any required institution is missing or unstable, stop here and reassess the stack.

## 2) Create the Production application

1. Sign in to <https://enablebanking.com/cp/applications>.
2. Create a **Production** application for personal non-commercial usage.
3. Download the private key file (`.pem`) provided for your app.
4. Store it outside this repository when possible.
5. Restrict permissions:

```bash
chmod 400 /absolute/path/to/enablebanking.pem
```

Never commit this file.

## 3) Configure redirect URL

Use this redirect URL format in your Enable Banking application:

`https://<host>.ts.net/enablebanking/auth_callback`

Use the same value in your `.env` placeholder variable.

Why this remains private: the callback endpoint is served over Tailscale Serve, and the user browser is already connected to the tailnet during consent flow.

## 4) Prepare local config

1. Copy `.env.example` to `.env`.
2. Fill placeholders only.
3. Set `ENABLE_BANKING_PEM_PATH` to your local private key path.
4. Set `ENABLE_BANKING_REDIRECT_URL` to the exact `https://<host>.ts.net/enablebanking/auth_callback` value.

## 5) Bring up Actual

```bash
docker compose up -d
```

This repository uses the **nightly** Actual image because Enable Banking support is experimental.

## 6) Connect banks in Actual UI

In Actual:

1. Open your budget.
2. Go to **More → Bank Sync**.
3. Choose Enable Banking and provide app information.
4. Start institution linking and complete SCA in your bank app/browser.

Repeat per account as needed.

## 7) Re-consent operations

PSD2 consents commonly expire every 90 days. Use `scripts/check-consents.sh` to track and remind re-authentication windows.

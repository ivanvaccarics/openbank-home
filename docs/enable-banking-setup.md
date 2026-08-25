# Enable Banking setup for Actual Budget

## 1) Go / no-go check first

Before creating anything, verify every bank/account provider you plan to connect is
available in Enable Banking: <https://enablebanking.com/open-banking-apis>

Check each required provider for:

- Availability in your country and account type
- Stable connection status for ongoing sync

If any required provider is missing or unstable, stop here and reassess the stack.

## 2) Optional: create a Sandbox application for API testing

1. Sign in to <https://enablebanking.com/cp/applications>.
2. Register a new application and choose the **Sandbox** environment.
3. Enter an application name and whitelist the redirect URL described below.
4. Generate and download the private key file (`.pem`) for the application.
5. Note the application ID assigned by Enable Banking.

Use the Sandbox application with Enable Banking's Mock ASPSPs to test the
Enable Banking API without connecting a real bank account. Follow the official
[Sandbox documentation](https://enablebanking.com/docs/api/sandbox/) for its
Mock ASPSPs and test data.

Actual's Enable Banking documentation currently instructs users to select
**Production** and does not document Sandbox or Mock ASPSP support. Do not rely
on Sandbox for an end-to-end Actual test unless that support is confirmed in
the Actual version you run. A successful API-level Sandbox test also does not
verify the behavior of a specific bank's PSD2 API.

The application ID and private key belong to this environment. Do not reuse or
mix them with credentials from a Production application.

## 3) Create a Production application for real accounts

For the documented Actual integration:

1. Register a separate application and choose the **Production** environment.
2. Provide the additional application, privacy and contact details requested by
	Enable Banking.
3. Generate and download a new private key file (`.pem`).
4. Activate the application using either:
	- **Restricted mode** to link and test only your own whitelisted accounts.
	- **Unrestricted mode** if you need full activation, which requires Enable
	  Banking review and the applicable commercial onboarding.

For this personal setup, restricted mode is the appropriate Production path
because access remains limited to your linked accounts.

For either environment:

1. Store the private key outside this repository when possible.
2. Restrict permissions:

```bash
chmod 400 /absolute/path/to/enablebanking.pem
```

Never commit this file.

## 4) Configure redirect URL

Use this redirect URL format in the Enable Banking application:

`https://<host>.ts.net/enablebanking/auth_callback`

Register the exact URL in each application you use, and use the same value in
your `.env` placeholder variable.

Why this remains private: the callback endpoint is served over Tailscale Serve, and the user browser is already connected to the tailnet during consent flow.

## 5) Prepare local config

1. Copy `.env.example` to `.env`.
2. Fill placeholders only.
3. Set `ENABLE_BANKING_APP_ID` to the Production application ID used by Actual.
4. Set `ENABLE_BANKING_PEM_PATH` to its matching private key path.
5. Set `ENABLE_BANKING_REDIRECT_URL` to the exact `https://<host>.ts.net/enablebanking/auth_callback` value.

These values are operator references. Actual asks for the application ID and
private key through **More → Bank Sync**; the container does not read these
variables directly.

## 6) Bring up Actual

```bash
docker compose up -d
```

This repository uses the **nightly** Actual image because Enable Banking support is experimental.

## 7) Connect banks in Actual UI

In Actual:

1. Open your budget.
2. Go to **More → Bank Sync**.
3. Choose Enable Banking and provide the Production application ID and its
	matching private key.
4. Select your bank and complete SCA in your bank app/browser.

Repeat per account as needed.

## 8) Re-consent operations

PSD2 consents commonly expire every 90 days. Use `scripts/check-consents.sh` to track and remind re-authentication windows.

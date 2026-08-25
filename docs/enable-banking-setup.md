# Enable Banking setup for Actual Budget

This walkthrough starts from a fresh checkout and follows dependency order. In
particular, obtain and verify the final Tailscale HTTPS URL before registering
the Enable Banking redirect URL.

## 1) Check prerequisites and bank support

Install Docker Engine with Docker Compose v2 and Tailscale on the host. Confirm
the commands are available:

```bash
docker --version
docker compose version
tailscale version
```

Before creating anything, verify every bank and account type you plan to connect
at <https://enablebanking.com/open-banking-apis>. Check both availability in
your country and the current connection status. If a required provider is
missing or unstable, reassess the stack before continuing.

## 2) Create the local configuration

From the repository root:

```bash
cp .env.example .env
chmod 600 .env
```

Open `.env` and configure local values such as `ACTUAL_PORT` and `TZ`. Leave the
example Enable Banking application ID and key path unchanged for now. Replace
the Tailscale hostname and redirect URL after the node joins the tailnet.

The Enable Banking variables in `.env` are private operator references. Actual
asks for the application ID and key through its UI; the container does not read
these variables directly.

## 3) Connect the host to Tailscale

Sign in to Tailscale on the server:

```bash
tailscale up
tailscale status
```

If `tailscale up` prints an authentication URL, open it and approve the host.
Confirm that the node appears in the Tailscale admin console and that MagicDNS
is enabled. See [Tailscale setup](tailscale-setup.md) for detailed checks.

Retrieve the node's fully qualified DNS name from the admin console or inspect
the `Self.DNSName` field in:

```bash
tailscale status --json
```

It normally resembles `raspberrypi.example-tailnet.ts.net`. This DNS name is
assigned by Tailscale; `tailscale serve` uses it but does not create it.

Update these values in `.env`, without a trailing dot in the hostname:

```dotenv
TS_HOSTNAME=raspberrypi.example-tailnet.ts.net
ENABLE_BANKING_REDIRECT_URL=https://raspberrypi.example-tailnet.ts.net/enablebanking/auth_callback
```

## 4) Start and verify Actual locally

Start the container:

```bash
docker compose up -d
docker compose ps
```

Wait until the `actual` service is healthy. If it does not become healthy,
inspect its logs before continuing:

```bash
docker compose logs --tail=100 actual
```

The service is bound only to loopback. Verify the default local port, or replace
`5006` if you changed `ACTUAL_PORT`:

```bash
curl --fail --silent --show-error http://127.0.0.1:5006/ >/dev/null
```

## 5) Publish Actual privately with Tailscale Serve

Configure the tailnet-only HTTPS proxy:

```bash
./scripts/tailscale-serve.sh
tailscale serve status
```

The status must show HTTPS forwarding to
`http://127.0.0.1:<ACTUAL_PORT>`. Never use `tailscale funnel`: Funnel would
publish Actual to the public internet.

Install Tailscale on the phone or computer used for setup, sign in to the same
tailnet, and open `https://<TS_HOSTNAME>`.

Continue only after Actual loads without a certificate warning. The callback to
register with Enable Banking is now known and served by the same HTTPS origin:

`https://<TS_HOSTNAME>/enablebanking/auth_callback`

The callback remains private because the browser performing the authorization
flow is connected to the tailnet.

## 6) Optional: create an Enable Banking Sandbox application

Sandbox is useful for testing the Enable Banking API with Mock ASPSPs without
connecting a real bank account:

1. Sign in to <https://enablebanking.com/cp/applications>.
2. Register a new application and choose **Sandbox**.
3. Enter an application name.
4. Add the exact `ENABLE_BANKING_REDIRECT_URL` from `.env` to the allowed
   redirect URLs.
5. Generate and download the private key (`.pem`).
6. Record the assigned application ID.

Follow the official
[Sandbox documentation](https://enablebanking.com/docs/api/sandbox/) for Mock
ASPSPs and test data.

Actual's documentation currently instructs users to select **Production** and
does not document Sandbox or Mock ASPSP support. Treat Sandbox as an API-level
test unless support is confirmed in the Actual version you run. Keep Sandbox
and Production IDs and keys separate.

## 7) Create the Production application for Actual

For the documented Actual integration:

1. In <https://enablebanking.com/cp/applications>, register another application.
2. Choose **Production**.
3. Enter the requested application, contact, privacy policy and terms details.
4. Add the exact `ENABLE_BANKING_REDIRECT_URL` from `.env` to the allowed
   redirect URLs. The scheme, hostname, path and trailing slash must match.
5. Generate and download a new private key (`.pem`).
6. Record the Production application ID.
7. Activate **Restricted mode** and link your own accounts in the Enable Banking
   interface.

Restricted mode is appropriate for this personal setup because API access is
limited to your linked accounts. Unrestricted activation is intended for wider
use and requires Enable Banking review and applicable commercial onboarding.

## 8) Protect and record the Production credentials

Move the downloaded Production key to the path chosen for local secrets. For
the example path in `.env`:

```bash
mkdir -p secrets
mv ~/Downloads/<production-app-id>.pem secrets/enablebanking.pem
chmod 400 secrets/enablebanking.pem
```

Replace `<production-app-id>` with the downloaded filename. Never commit the
key. Confirm Git ignores it:

```bash
git check-ignore -v secrets/enablebanking.pem
```

Update the operator references in `.env` with the matching Production values:

```dotenv
ENABLE_BANKING_APP_ID=<production-app-id>
ENABLE_BANKING_PEM_PATH=./secrets/enablebanking.pem
```

The key is deliberately not mounted into the container. Upload it through
Actual's Bank Sync setup in the next step.

## 9) Configure Enable Banking in Actual

From a device connected to the tailnet, open `https://<TS_HOSTNAME>` and:

1. Open your budget.
2. Go to **More → Bank Sync**.
3. Choose **Set up Enable Banking**.
4. Paste the Production application ID.
5. Upload the matching Production `.pem` file.
6. Save the provider configuration.

If Actual rejects the credentials, first confirm that the application ID and
private key come from the same Production application.

## 10) Link an account and run the first sync

In Actual:

1. Open the account to connect, or create it first if needed.
2. Select **Link account → Enable Banking**.
3. Choose the country and bank.
4. Follow the authorization flow and complete SCA in the bank app or browser.
5. Return to Actual and associate the remote account with the local account.
6. Run **Bank Sync**.
7. Confirm that transactions appear once and with plausible dates and amounts.

Repeat the linking steps for each account. If the callback fails, compare the
browser callback URL with the allowed redirect URL character for character and
confirm that the device is still connected to Tailscale.

## 11) Configure ongoing operations

PSD2 consents commonly expire every 90 days. Use
`scripts/check-consents.sh` to track reauthorization windows. Also configure and
test encrypted backups as described in [Backup and restore](backup-restore.md),
because Actual stores bank-sync secrets in its server-side database.

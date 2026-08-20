# Contributing

Thanks for your interest! This is a small, opinionated homelab project, but
improvements — especially bank-compatibility reports and documentation fixes —
are very welcome.

---

## 🚨 Rule zero: never commit secrets

This is a **public** repository about **personal finance**. Before your first commit:

```bash
pip install pre-commit
pre-commit install
```

This installs a [`gitleaks`](https://github.com/gitleaks/gitleaks) hook that blocks
commits containing credentials.

Never commit — not even in an example, not even redacted:

- `.env` files, `*.pem`, `*.key`, or anything from `secrets/`
- Real IBANs, account IDs, Application IDs, transaction data
- Real tailnet hostnames — use `raspberrypi.tailnet-XXXX.ts.net`
- Screenshots showing balances or account numbers

If a secret slips through, see the revocation procedure in [SECURITY.md](SECURITY.md).

---

## How to contribute

1. Fork and branch off `main` (`feat/…`, `fix/…`, `docs/…`)
2. Make your change
3. Run the checks below
4. Open a pull request describing *why*, not just *what*

### Local checks

```bash
# Shell scripts
shellcheck scripts/*.sh

# Compose file
docker compose config --quiet

# Secret scan
gitleaks detect --no-git --verbose

# Everything the hooks do
pre-commit run --all-files
```

CI runs the same checks on every pull request.

---

## Style

**Shell** — `#!/usr/bin/env bash`, `set -euo pipefail`, a `--help` flag, quoted
variable expansions, and `shellcheck`-clean.

**Docs** — English, tables over prose where possible, fenced code blocks with a
language hint, and cross-links to related documents.

**Commits** — [Conventional Commits](https://www.conventionalcommits.org/):
`feat:`, `fix:`, `docs:`, `chore:`, `ci:`.

---

## Especially useful contributions

- **Bank compatibility reports.** Did Enable Banking work with your institution?
  Open an issue with the bank name, country, and what did or didn't sync.
- **Non-Italian setups.** This project is Italy-flavoured; generalisations are welcome.
- **Documentation clarity.** If a step confused you, it will confuse the next person.

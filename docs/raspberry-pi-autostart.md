# Raspberry Pi 3 and automatic startup

## Raspberry Pi 3 Model B compatibility

The Compose flow can run on a Raspberry Pi 3 Model B. Its ARMv8 CPU is
compatible with the ARM64 container image, but its 1 GB of RAM makes it the
minimum practical configuration.

Use:

- Raspberry Pi OS Lite **64-bit**; a 32-bit installation is not recommended
- the existing `nightly-alpine` image in `docker-compose.yml`
- a reliable power supply and, preferably, USB storage rather than a microSD
  card for the persistent `data/` directory
- no other memory-heavy services on the Pi

Expect slower startup, imports, updates, and synchronization than on a Pi 4 or
5. Keep regular backups and monitor memory and storage. The setup instructions
otherwise remain unchanged.

## Start the stack manually

Keep the repository in a stable location, for example:

```text
/home/pi/openbank-home
```

Configure `.env` in that directory, then run:

```bash
cd /home/pi/openbank-home
./scripts/start.sh
```

The script runs `docker compose up -d` and reapplies the tailnet-only Tailscale
Serve configuration. It is idempotent, so it can also be used after an update
or an interruption.

## Start automatically after reboot

The `restart: unless-stopped` policy already restarts the Actual container when
Docker starts. The systemd unit below additionally runs the complete startup
script and verifies the Tailscale Serve configuration.

Create `/etc/systemd/system/openbank-home.service`:

```ini
[Unit]
Description=openbank-home stack
Wants=network-online.target
After=network-online.target docker.service tailscaled.service
Requires=docker.service tailscaled.service

[Service]
Type=oneshot
RemainAfterExit=yes
User=pi
Group=pi
ExecStart=/home/pi/openbank-home/scripts/start.sh

[Install]
WantedBy=multi-user.target
```

Modify these values for the Pi:

| Value | What to set |
|---|---|
| `User` and `Group` | The non-root account that owns the repository |
| `ExecStart` | The absolute path to `scripts/start.sh` in the clone |

That user must be able to run Docker without `sudo` and Tailscale Serve. If
needed, grant Docker access, then log out and back in:

```bash
sudo usermod -aG docker pi
sudo tailscale set --operator=pi
sudo tailscale debug prefs | grep OperatorUser
```

Replace `pi` in both commands with the account configured in the unit. Enable
and test the service:

The output should identify the same non-root user configured in the systemd
unit (for example, `pi`). If it is missing or incorrect, rerun
`sudo tailscale set --operator=pi`, replacing `pi` with your service account.

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now openbank-home.service
sudo systemctl status openbank-home.service
journalctl -u openbank-home.service -b
```

After changing the unit, run `sudo systemctl daemon-reload` and restart it.
After changing `.env` or `docker-compose.yml`, restart it directly:

```bash
sudo systemctl restart openbank-home.service
```

To verify reboot recovery, reboot the Pi and check:

```bash
docker compose -f /home/pi/openbank-home/docker-compose.yml ps
systemctl status openbank-home.service
tailscale serve status
```

Do not use `tailscale funnel`: it would expose the service to the public
internet.

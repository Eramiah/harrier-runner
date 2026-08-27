# harrier-runner

**harrier-runner** runs Harrier's pull-request reviews on your own machine. Install it once, sign in
once, and leave it running — it picks up reviews assigned to you and posts the results.

---

## Requirements

- macOS, Linux, or Windows.
- The **Claude** CLI, installed and signed in (`claude` on your PATH).
- **git**, signed in to the repositories you'll review.
- The **server address** and **client ID** from your Harrier admin.

---

## Install

Download the binary for your system from the [**Releases**](../../releases) page, verify it, and put it
on your PATH.

**macOS / Linux:**

```sh
OS="$(uname -s | tr A-Z a-z)"
ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/aarch64/arm64/')"
BASE="https://github.com/Eramiah/harrier-runner/releases/latest/download"

curl -fL "$BASE/harrier-runner-$OS-$ARCH" -o harrier-runner
curl -fL "$BASE/SHA256SUMS" -o SHA256SUMS
sha256sum -c SHA256SUMS --ignore-missing 2>/dev/null | grep "harrier-runner-$OS-$ARCH"   # expect: OK
chmod +x harrier-runner && sudo mv harrier-runner /usr/local/bin/harrier-runner
```

**Windows:** download `harrier-runner-windows-amd64.exe` from Releases; optionally verify with
`CertUtil -hashfile harrier-runner-windows-amd64.exe SHA256` against `SHA256SUMS`.

---

## Set up (one time)

```sh
harrier-runner init --server <server-address> --client-id <client-id>
```

Opens a GitHub device sign-in in your browser, then saves your settings.

---

## Run

```sh
harrier-runner run
```

Leave it running; it picks up reviews as they come. Press **Ctrl-C** to stop. For an always-on setup
that survives reboots (and, on Windows, avoids the console pause), install it as a background service — see
below.

---

## Run as a background service (recommended)

Onboard first (`harrier-runner init …`), then install the service for your OS.

**Linux (systemd user service):**

```sh
mkdir -p ~/.config/systemd/user
cat > ~/.config/systemd/user/harrier-runner.service <<'UNIT'
[Unit]
Description=Harrier runner
After=network-online.target
Wants=network-online.target
[Service]
ExecStart=%h/.local/bin/harrier-runner run
Restart=always
RestartSec=10
[Install]
WantedBy=default.target
UNIT
# edit ExecStart if your binary is elsewhere (e.g. /usr/local/bin/harrier-runner)
systemctl --user daemon-reload
systemctl --user enable --now harrier-runner
loginctl enable-linger "$USER"     # keep it running while you're logged out
```

**macOS (launchd agent):**

```sh
cat > ~/Library/LaunchAgents/com.harrier.runner.plist <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0"><dict>
  <key>Label</key><string>com.harrier.runner</string>
  <key>ProgramArguments</key>
  <array><string>/usr/local/bin/harrier-runner</string><string>run</string></array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>StandardErrorPath</key><string>/tmp/harrier-runner.log</string>
  <key>StandardOutPath</key><string>/tmp/harrier-runner.log</string>
</dict></plist>
PLIST
launchctl load -w ~/Library/LaunchAgents/com.harrier.runner.plist
```

**Windows** — use a service wrapper that **always restarts** the process, e.g. [nssm](https://nssm.cc):

```bat
nssm install harrier-runner "C:\path\to\harrier-runner-windows-amd64.exe" run
nssm set harrier-runner AppExit Default Restart
nssm start harrier-runner
```

A real service wrapper is needed on Windows because after an automatic update the runner exits cleanly for
its supervisor to relaunch on the new version (see below). Task Scheduler ("at log on", "restart on
failure") also survives reboots, but it will **not** relaunch after an update (a clean exit isn't a
failure), so you'd have to start it again by hand after each update.

---

## Automatic updates

The runner keeps itself up to date: on startup and periodically between reviews it checks for a newer
release, verifies its signature, and swaps itself in. Turn it off with `"auto_update": false` in
`~/.harrier/runner/config.json` (Windows: `%USERPROFILE%\.harrier\runner\config.json`);
`"update_check_interval_hours"` sets the cadence (default 6).

> **Windows:** a running `.exe` can't overwrite itself, so after an update the runner exits and the
> service manager relaunches it. If you started it interactively (not as a service), start it again after
> an update — or run it as a service so it relaunches automatically.

---

## Stop / remove

- **Stop:** Ctrl-C, or stop the background service.
- **Remove:** delete the `harrier-runner` binary and the `~/.harrier/runner/` folder (Windows:
  `%USERPROFILE%\.harrier\runner`).

---

## Trouble?

- **Reviews aren't picked up** — re-run `harrier-runner init …` with the address and ID from your admin.
- **`claude` or `git` not found** — install and sign in to both, then retry.
- Anything else — contact whoever set up Harrier for your team.

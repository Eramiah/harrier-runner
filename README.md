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

This opens a GitHub device sign-in in your browser, saves your settings, and **installs a background
service that starts now and on every boot/login** (systemd on Linux, launchd on macOS, a native Windows
Service on Windows) — so the runner is always up and "runner offline" is a non-issue. Add `--no-service`
to skip the service and run it by hand.

> **Windows:** registering the service needs administrator rights — run `init` (or `install-service`) from
> an **elevated** PowerShell/Command Prompt. Not elevated? `init --no-service` onboards you; then run
> `harrier-runner run` in a terminal.

---

## Everyday use

The `harrier-runner` command is a thin controller/viewer — the **service** does the actual reviewing.

```sh
harrier-runner                  # read-only view: is the service running? + how to see activity
harrier-runner status --follow  # tail live activity until Ctrl-C
harrier-runner start|stop|restart
harrier-runner uninstall        # remove the service (keeps your settings)
```

Running bare `harrier-runner` shows status and, if the service is installed but stopped, starts it. It
never starts a second copy — only one runner per machine. (On Windows, viewing status needs no elevation;
`start`/`stop`/`install-service`/`uninstall` do — run them from an elevated prompt.)

**Already running an older runner?** After it self-updates, run `harrier-runner install-service` once to
adopt the service — no re-onboarding, no cleanup.

---

## Automatic updates

The runner keeps itself up to date: on startup and periodically between reviews it checks for a newer
release, verifies its signature, and swaps itself in. Turn it off with `"auto_update": false` in
`~/.harrier/runner/config.json` (Windows: `%USERPROFILE%\.harrier\runner\config.json`);
`"update_check_interval_hours"` sets the cadence (default 6).

> **Windows:** a running `.exe` can't overwrite itself, so after an update the runner exits and the Windows
> Service restarts it automatically (the service is configured to restart even on a clean exit). If you
> started it interactively in a terminal instead, start it again after an update.

---

## Stop / remove

- **Stop / start:** `harrier-runner stop` / `harrier-runner start` (Windows: from an elevated prompt).
- **Remove the service:** `harrier-runner uninstall` (keeps your settings so you can re-add it).
- **Remove everything:** after `uninstall`, delete the `harrier-runner` binary and the
  `~/.harrier/runner/` folder (Windows: `%USERPROFILE%\.harrier\runner`).

---

## Trouble?

- **Reviews aren't picked up** — re-run `harrier-runner init …` with the address and ID from your admin.
- **`claude` or `git` not found** — install and sign in to both, then retry.
- Anything else — contact whoever set up Harrier for your team.

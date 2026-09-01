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
harrier-runner                  # read-only view: service state + current job + recent reviews
harrier-runner status --follow  # tail the live log until Ctrl-C
harrier-runner start|stop|restart
harrier-runner tray             # menu-bar/systray viewer (built in on Windows; separate build on macOS/Linux)
harrier-runner uninstall        # remove the service (keeps your settings)
```

The view shows whether the service is running, what it's reviewing right now (with elapsed time and a
"last seen" liveness stamp), and the last few review outcomes.

**Tray viewer (optional):** `harrier-runner tray` shows the same info as a native menu-bar/systray icon
(the Harrier eagle) that sits in the background; hover for the current job and state. It's read-only
(start/stop/restart still go through the CLI).

- **Windows:** built right into the standard `harrier-runner.exe` — just run `harrier-runner tray`, no separate
  download. Because it's the same binary, **the tray auto-updates with the runner**.
- **macOS / Linux:** the tray needs a GUI toolkit (Cocoa / GTK), so it ships as a separate `harrier-runner-tray`
  build; the standard binary prints how to get it if you run `tray` on it.

`harrier-runner tray --install-autostart` makes it launch at every login (Windows startup / macOS menu-bar /
Linux autostart); `--uninstall-autostart` removes it. On Windows you can also add a Start Menu shortcut:

```powershell
$exe = (Get-Command harrier-runner).Source
$lnk = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Harrier Runner Tray.lnk"
$s = (New-Object -ComObject WScript.Shell).CreateShortcut($lnk)
$s.TargetPath = $exe; $s.Arguments = "tray"; $s.Save()
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

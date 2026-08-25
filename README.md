# harrier-runner

**harrier-runner** reviews pull requests on **your own machine**, using **your own Claude
subscription**. When a repository you've been set up for has a PR that needs a review, the runner does
that review locally and posts the result — so it's spent against your Claude plan, not a shared bill.

It's a single small program with no background dependencies. You install it once, sign in once, and leave
it running (or install it as a background service). When there's nothing to review, it sits idle.

---

## What it does on your machine

When there's a review waiting for you, the runner:

1. Checks out the exact commit to be reviewed, using your existing **git / GitHub** sign-in.
2. Runs **Claude** over that code locally, using your existing `claude` sign-in.
3. Sends the review back and posts it on the pull request.

That's all it does. It only acts when there's a review assigned to you; the rest of the time it waits. It
adds nothing to your system beyond the one binary and a small sign-in file in your home folder. The code
is checked out and reviewed **on your machine**; the review is done by **Claude** (so, as with any use of
Claude, the code you review is processed by Claude to produce the review). The runner itself uploads
nothing else — it just sends the finished review back to be posted.

---

## Requirements

- macOS, Linux, or Windows.
- The **Claude** command-line app, already signed in (`claude` on your PATH).
- **git**, already signed in to the repositories you'll review.
- The **server address** and **sign-in ID** from whoever set up Harrier for your team (you'll paste these
  once, during setup).

---

## Install

Download the binary for your system from the [**Releases**](../../releases) page, check it, and put it on
your PATH.

**macOS / Linux** (no GitHub account needed — plain download):

```sh
OS="$(uname -s | tr A-Z a-z)"
ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/aarch64/arm64/')"
BASE="https://github.com/Eramiah/harrier-runner/releases/latest/download"

curl -fL "$BASE/harrier-runner-$OS-$ARCH" -o harrier-runner
curl -fL "$BASE/SHA256SUMS" -o SHA256SUMS
# verify (you should see a line ending in "OK"):
sha256sum -c SHA256SUMS --ignore-missing 2>/dev/null | grep "harrier-runner-$OS-$ARCH"
chmod +x harrier-runner && sudo mv harrier-runner /usr/local/bin/harrier-runner
```

**Windows:** download `harrier-runner-windows-amd64.exe` from Releases, and (optionally) verify it against
`SHA256SUMS` with `CertUtil -hashfile harrier-runner-windows-amd64.exe SHA256`.

---

## Set up (one time)

```sh
harrier-runner init --server <server-address> --client-id <sign-in-id>
```

Use the **server address** and **sign-in ID** your Harrier admin gave you. This opens a short code in your
browser to confirm it's you (a normal GitHub device sign-in — no new password), then saves your settings.

---

## Run

```sh
harrier-runner run
```

It will keep running and pick up reviews as they come. Press **Ctrl-C** to stop.

To keep it always on (so it's there even after a reboot or logout), install it as a background service —
see the short **service** notes included with the binary for macOS (launchd), Linux (systemd), and Windows.

---

## Stop / remove

- **Stop:** press Ctrl-C, or stop the background service if you installed one.
- **Remove:** delete the `harrier-runner` binary and the `~/.harrier/runner/` folder (Windows:
  `%USERPROFILE%\.harrier\runner`). That's everything it stored.

---

## Privacy & what it touches

- It uses **your** existing `claude` and `git` sign-ins — you don't hand over any new credentials.
- The code is checked out and reviewed **on your machine**. The review itself is done by **Claude**, so
  the code you review is processed by Claude (exactly like any other code you'd run Claude on). Beyond
  that, the runner sends nothing except the finished review.
- The one file it stores is a sign-in token in `~/.harrier/runner/` (readable only by you).
- It only reviews repositories you've been set up for, and only when there's a review assigned to you.

---

## Trouble?

- **"not signed in" / reviews aren't picked up** — re-run `harrier-runner init …` with the address and ID
  from your admin.
- **`claude` or `git` not found** — make sure both are installed and signed in, then try again.
- Anything else — contact whoever set up Harrier for your team.

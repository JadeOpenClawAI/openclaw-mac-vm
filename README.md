# Tart macOS VM for BlueBubbles (and OpenClaw)

Run BlueBubbles and/or OpenClaw inside a Tart macOS VM on Apple Silicon.

This project gives you:
- Packer templates to build VM images
- Host-side launchd + SwiftBar integration
- A safer isolation model vs running directly on host macOS

---

## Quick Start (10-minute path)

If you want the fastest path to a working BlueBubbles VM:

1) Build BlueBubbles VM image

```bash
./scripts/build.sh bluebubbles tahoe
```

2) Install host integration (auto-start + control script + optional SwiftBar)

```bash
VM_NAME=tahoe-base BRIDGE_IF=en0 SWIFTBAR_ENABLE=true ./scripts/install-host-integration.sh
```

3) First run in graphics mode

```bash
~/Scripts/tart-vm-control.sh set-graphics
~/Scripts/tart-vm-control.sh restart
```

4) In the VM:
- Sign in to **Messages** with your Apple ID
- Complete BlueBubbles setup (Google Project step can be skipped if not needed)
- Enable BlueBubbles **Run on startup / launch**

5) Configure OpenClaw BlueBubbles webhook settings to match BlueBubbles server settings
- `channels.bluebubbles.serverUrl`
- `channels.bluebubbles.password`
- `channels.bluebubbles.webhookPath`

6) Switch VM back to headless mode

```bash
~/Scripts/tart-vm-control.sh set-headless
~/Scripts/tart-vm-control.sh restart
```

That’s it — you now have a persistent VM-backed BlueBubbles environment with host-level isolation.

---

## Why run this in a VM?

If your automation stack handles webhooks, private API integrations, and credentials, a VM is a safer boundary:

- **Host isolation:** keep your daily-driver macOS cleaner and lower-risk
- **Blast radius reduction:** mistakes/experiments stay inside VM
- **Rebuildability:** image workflow (clone/snapshot/rebuild) instead of snowflake setup
- **Operational sanity:** easier rollback and repeatable upgrades

For BlueBubbles Private API workflows specifically, this model is practical:
- **Host macOS:** keep SIP enabled
- **BlueBubbles VM:** use a VM image/workflow that supports your private API requirements

> Always verify SIP/private-api prerequisites in your exact image/tag + macOS version.

---

## Repository layout

- `packer/bluebubbles.pkr.hcl` — build Tart VM image with BlueBubbles installed
- `packer/openclaw.pkr.hcl` — build Tart VM image with OpenClaw installed
- `scripts/build.sh` — `packer init` + `packer build` helper
- `scripts/install-host-integration.sh` — install launchd + optional SwiftBar integration
- `host/scripts/tart-vm-control.sh` — launchd control script (headless/graphics toggle)
- `host/launchagents/com.user.tart-vm.plist` — templated LaunchAgent
- `host/swiftbar/tart-vm.5s.sh` — SwiftBar status/control plugin

---

## Prerequisites (host)

- Apple Silicon Mac
- [Tart](https://tart.run)
- [Packer](https://developer.hashicorp.com/packer)
- Homebrew
- (Optional) SwiftBar

Recommended quick checks:

```bash
tart --version
packer version
```

---

## Build VM images

### BlueBubbles image

```bash
cd packer
packer init .
packer build bluebubbles.pkr.hcl
```

### OpenClaw image

```bash
cd packer
packer init .
packer build openclaw.pkr.hcl
```

Optional version override:

```bash
packer build -var macos_version=sequoia bluebubbles.pkr.hcl
```

Or use helper script:

```bash
./scripts/build.sh bluebubbles
./scripts/build.sh openclaw
./scripts/build.sh bluebubbles tahoe
```

---

## Install host integration (launchd + SwiftBar)

```bash
./scripts/install-host-integration.sh
```

Useful overrides:

```bash
VM_NAME=tahoe-base \
BRIDGE_IF=en0 \
PLIST_LABEL=com.user.tart-vm \
SWIFTBAR_ENABLE=true \
./scripts/install-host-integration.sh
```

Installs:
- `~/Scripts/tart-vm-control.sh`
- `~/Library/LaunchAgents/<label>.plist`
- `~/SwiftBar/tart-vm.5s.sh` (if enabled)

`RunAtLoad` + `KeepAlive` are enabled, so host reboots and VM exits auto-recover.

---

## First boot checklist (required)

### 1) Run in graphics mode at least once
Before headless-only operation, do first setup interactively:

```bash
~/Scripts/tart-vm-control.sh set-graphics
~/Scripts/tart-vm-control.sh restart
```

### 2) Sign into Messages with your Apple ID
For BlueBubbles/iMessage workflows, this must be done interactively in the VM.

### 3) Configure BlueBubbles in VM
Run through BlueBubbles setup in the VM:

- You can skip the Google Project step if not needed for your use-case.
- Ensure BlueBubbles server is running and reachable.
- Enable **Run on startup / launch** in BlueBubbles so headless starts keep it connected.

### 4) Configure OpenClaw webhook to match BlueBubbles
OpenClaw config keys must match BlueBubbles webhook settings:
- `channels.bluebubbles.serverUrl`
- `channels.bluebubbles.password`
- `channels.bluebubbles.webhookPath`

BlueBubbles webhook URL/path and OpenClaw webhook config must be consistent.

### 5) Switch back to headless mode

```bash
~/Scripts/tart-vm-control.sh set-headless
~/Scripts/tart-vm-control.sh restart
```

---

## OpenClaw setup note (manual vs automated)

The `openclaw.pkr.hcl` template installs the app, but **full OpenClaw onboarding is best done manually in GUI first** (auth flows, channel setup, webhooks, runtime preferences).

You can automate further if you:
- extend the Packer template with post-install config provisioning
- and/or use Tart directory mounts to inject config/scripts safely

If you plan to run OpenClaw heavily in-VM, consider extending the template with commonly used tooling (example: `imsg` helper CLI, ffmpeg, jq/yq, tmux, etc.) based on your workflow.

---

## Tart directory mounts (recommended for config + scripts)

Tart supports host-to-guest directory mounts, which are useful for:
- injecting OpenClaw config/scripts
- sharing logs/artifacts
- keeping build/provision files on host

Example:

```bash
tart run --dir=project:~/src/project vm
```

In macOS guest, mounted path appears under:

- `/Volumes/My Shared Files/project`

Read-only mount:

```bash
tart run --dir=project:~/src/project:ro vm
```

This is often cleaner than baking every file into the VM image.

---

## Control script usage

```bash
~/Scripts/tart-vm-control.sh start
~/Scripts/tart-vm-control.sh stop
~/Scripts/tart-vm-control.sh restart
~/Scripts/tart-vm-control.sh status
~/Scripts/tart-vm-control.sh set-headless
~/Scripts/tart-vm-control.sh set-graphics
~/Scripts/tart-vm-control.sh toggle-mode-restart
```

---

## Notes and gotchas

- `BRIDGE_IF` defaults to `en0`; adjust for your host network setup.
- Template defaults use VM names like `tahoe-base`; set `VM_NAME` accordingly in installer usage.
- BlueBubbles Packer template includes a Messages “poke” LaunchAgent to improve long-running responsiveness.
- Tart default credentials on many Cirrus images are `admin/admin` (verify image docs for your tag).

---

## References

### Tart
- Quick Start: https://tart.run/quick-start/
- Mounting directories: https://tart.run/quick-start/#mounting-directories
- Accessing mounted dirs in macOS guests: https://tart.run/quick-start/#accessing-mounted-directories-in-macos-guests
- Packer integration: https://tart.run/integrations/packer/
- Cirrus macOS image templates: https://github.com/cirruslabs/macos-image-templates

### BlueBubbles
- Main docs: https://docs.bluebubbles.app/
- REST API + Webhooks: https://docs.bluebubbles.app/server/developer-guides/rest-api-and-webhooks
- Postman API collection: https://documenter.getpostman.com/view/765844/UV5RnfwM

### SwiftBar
- Repo/docs: https://github.com/swiftbar/SwiftBar
- Install via Homebrew: `brew install swiftbar`

---

## Next improvements (optional)

- Add Makefile targets (`make build-bluebubbles`, `make build-openclaw`, `make install-host`)
- Add cloud tunnel bootstrap (Cloudflare/ngrok)
- Add VM healthcheck + watchdog scripts
- Add OpenClaw pre-config template and validation script

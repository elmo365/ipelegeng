# Work Handoff - Ipelege

**Saved:** Thursday, 2026-08-20, 06:12 (+02:00)
**Branch:** main
**Last commit:** 16c56cb Build the Flutter shell: theme, navigation, components

## What I was working on

Two things this session. First, **provisioning the production VPS** — the Azure
arm64 box the previous handoff earmarked for the backend stack. Got in, secured
access, fixed a storage trap, and stood up the full data stack in Docker, all
arm64-native. Second, **resolving the schema-blocking open questions** through
the interview skill, which reframed most of them as admin/policy rather than
coding decisions, and led to a **documentation pass** consolidating the wallet
system and marking the ledger-grain decision resolved.

## Files changed this session

Docs (staged for this commit):

- **A `docs/wallet.md`** — new. The consolidated wallet system: one wallet per
  provider, the three category fee shapes, refunds-as-reversals, admin
  integration, and two mermaid diagrams (full flow + wallet data-flow).
- **M `docs/database.md`** — ledger-grain open item marked resolved (one per
  provider).
- **M `docs/data-model.md`** — same, in the open list and the `LEDGER_ACCOUNT`
  definition.
- **M `docs/open-questions.md`** — ledger grain moved to "Resolved since last
  revision"; its two duplicates (Technical, Monetization) marked `[x]`.
- **M `docs/monetization.md`, `docs/dfd.md`** — cross-links into `wallet.md`.
- **M `README.md`** — `wallet.md` added to the doc index.
- **A `.env.example`** — placeholder template (safe to commit).

Infra (on the VM and on this PC, not in git):

- `~/.agents/secrets/ipelege-vm.env` and the repo's gitignored `.env` — VM creds,
  SSH key path, Azure context, and generated stack credentials.
- `~/.ssh/ipelege_vm_ed25519` (+ `.pub`), `~/.ssh/ipelege_known_hosts`, and an
  `ipelege` host alias in `~/.ssh/config`.

## What is working

- **VPS access:** `ssh ipelege` logs in by key, no password. Host key pinned.
- **The VM:** Azure `Standard_D2pds_v6`, Ubuntu 24.04, **aarch64**, 2 vCPU /
  7.7 GB, SouthAfricaNorth zone 3, passwordless sudo. Public IP 40.127.10.234.
- **Persistent storage:** a **64 GB Premium SSD** managed disk mounted at `/data`
  by UUID (fstab, survives reboot), owned by the app user. Docker data-root
  relocated to `/data/docker`.
- **The stack — all arm64-native, all localhost-bound, all `restart:
  unless-stopped`, Docker enabled (survives reboot):**
  - Postgres **16.4 + PostGIS 3.4.3** (image `imresamu/postgis:16-3.4`) — healthy,
    extensions enabled.
  - Redis 7 (auth on) — healthy.
  - MinIO (latest) — healthy.
  - Caddy 2 — responding on 127.0.0.1:8080 (placeholder config).
- **Docs:** wallet flow consolidated and cross-linked; ledger-grain decision
  resolved and corroborated three ways (product call, data-model 1:1, design
  canvas).

## What is NOT working yet

- **No product screens / no backend app** — unchanged from last session. Every
  Flutter route still renders PlaceholderScreen. Django project not started.
- **The stack has no schema** — Postgres is running with PostGIS enabled but has
  no app tables. Deliberate: schema waits on the booking-state blocker (below).
- **Nothing is public** — Postgres/Redis/MinIO are localhost-only by design.
  Caddy has no domain and no NSG rule for 80/443, so it serves nothing externally.
- **Not a durable host.** The subscription is **"Azure for Students"** (~$100
  credit cap, `201300272@ub.ac.bw`). It auto-deallocated once mid-session. Fine
  for build/staging; a real hosting quote is still outstanding.
- **The 47-passing-tests claim** is carried from the prior handoff, not
  re-verified this session.

## Decisions made (and why)

- **One wallet per provider** (not per category). Corroborated by data-model's
  `USER ||--|| LEDGER_ACCOUNT` 1:1 and the design canvas, which calls "one
  wallet" its load-bearing decision. Sets the ledger PK; per-category reporting
  rides on `JOURNAL_TRANSACTION`, not on splitting the account. See
  `docs/wallet.md`.
- **Most "blockers" are admin/policy, not code** (user's framing). The verified
  badge's *meaning* is an ops decision; code stores a status flag with room for a
  tier, no migration. Dispute window/retention are config. Wallet naming is a
  label+legal question that doesn't touch the schema.
- **Key auth before provisioning** — password is in the transcript, so a key was
  pushed and login switched to it before any stack work.
- **Data on a managed disk, not the NVMe.** The 110 GB NVMe is an Azure "Direct
  Disk" = **ephemeral** (wiped on deallocate). Created a persistent Premium SSD
  for `/data` instead; NVMe left as free scratch.
- **Docker Compose** for the stack (user choice), data-root and all volumes on
  `/data`, everything bound to 127.0.0.1.
- **`imresamu/postgis`** over official `postgis/postgis` — the official image has
  no arm64 build and silently pulled amd64 (exec format error). imresamu is
  multi-arch with a real arm64 manifest.

## Things I tried that did NOT work - do not repeat these

- **`postgis/postgis:16-3.4` on arm64** — no arm64 manifest; pulls amd64, crashes
  with `exec format error`. Use `imresamu/postgis`.
- **`curl | sudo bash` installers** — blocked by the auto-mode classifier. Use
  stepwise apt-repository installs (worked for both azure-cli and docker).
- **Backgrounding `az login` over a one-shot SSH command** (`setsid ... &` /
  `nohup ... &`) — the SSH session hangs on the held channel and the wrapping
  `timeout` kills it, discarding output; the file never appears. Use
  `systemd-run --unit=... --collect` to fully detach, then read the output file
  in a *separate* SSH call.
- **`az login --use-device-code --only-show-errors`** — `--only-show-errors`
  suppresses the device-code prompt itself. Drop the flag.
- **Bash heredocs for large local files** — still true from last session; used
  the Write tool and `scp` for the compose files instead.

## Exact next steps to continue

1. **Push a handset/ emulator run of the Flutter shell** (still never run on a
   device — carried over).
2. **Decide the one true remaining code blocker:** what happens to
   already-accepted bookings when a category is revoked. `admin.md` says the
   Revoke action cannot ship until this is decided; it's a booking-state
   question, not a wallet one.
3. **Start the Django backend** against the running Postgres: `ssh ipelege`, then
   connect to `127.0.0.1:5432` (creds in secrets). PostGIS is enabled. With the
   ledger grain settled, the `LEDGER_ACCOUNT` / `JOURNAL_*` tables can now be
   modelled — one account per provider.
4. **Build the first real screens** (consumer Home, category browse, listing
   detail) — carried over.
5. **Add swap** on the VM (none currently) before real load; consider whether the
   student sub is the long-term host or whether to get the local Tier III quote
   (Digital Delta DC1) now.
6. **When a domain exists:** point Caddy at it, open the NSG for 80/443, and
   front MinIO/API through Caddy (config stub already in `/data/stack/Caddyfile`).

## Open questions / blockers

- **Already-accepted bookings on category revoke** — the last schema/behaviour
  blocker that is genuinely code. Blocks the admin Revoke action shipping.
- **Verified badge meaning** — admin/policy, not code. Ops must decide "raise the
  check vs lower the claim"; schema already stores a status.
- **Wallet naming vs compliance.md** — goes to counsel with the EPS question;
  does not change the schema.
- **Reversal policy** (who may raise, window, partial reversals, no-show fee),
  **negative-balance rule**, **min top-up**, **per-category commission rates** —
  all still open, tracked in their home docs and `wallet.md#open`.
- **Hosting** — student sub is not durable; local Tier III price still unquoted.
- **External/legal, unchanged:** EPS licensing position, data residency (DPA
  2024), KYC retention schedule, DPIA for GPS tracking.

# Work Handoff - Ipelege

**Saved:** Sunday, 16 August 2026, 14:23 (UTC+02:00)
**Branch:** main
**Last commit:** 5aea5f2 Add Ipelegeng specification documents

## What I was working on

Bootstrapping the Ipelege project repository. Four things: read the full
specification set in `docs/`, put the project under version control and push it
to `https://github.com/elmo365/ipelegeng`, stand up the code-intelligence
indexes (Serena, CodeGraph) so later sessions start warm, and correct the app
name throughout the documentation.

Ipelege is a multi-category informal-services marketplace for Botswana. The
repository is **pre-build** — 21 specification documents, no application code.

## Files changed this session

- **M** `README.md`, **M** `docs/*.md` (10 files) — app name corrected from
  "Ipelegeng" to **"Ipelege"**, 26 occurrences. Done after the initial commit,
  so `5aea5f2` still contains the old name.
- **M** `.gitignore` — added `.codegraph/` and `.serena/` to the editors/OS
  section so tooling indexes stay out of the repo.
- **A** `HANDOFF.md` — this file.
- **A** `handoffs/handoff.index.json`, `handoffs/.gitkeep` — handoff continuity
  files.
- Everything else (`README.md`, `CONTRIBUTING.md`, `docs/*`, the workspace file)
  was pre-existing content committed unchanged as the initial commit.

## What is working

- **Git is live and synced.** Repo initialised on `main`, initial commit
  `5aea5f2` covering all 25 files, remote `origin` added, pushed. Verified:
  `git ls-remote origin` returns the same SHA as local `HEAD`; working tree
  clean.
- **Push authentication works** via Windows Credential Manager (helper
  `manager`, user `elmo365`). No token needed in the environment.
- **Serena** project is registered and activated, with six memories written
  (`core`, `tech_stack`, `open_decisions`, `conventions`,
  `suggested_commands`, `task_completion`) capturing the spec's invariants,
  decided/undecided technology, and the research contradictions.
- **CodeGraph** initialised — `.codegraph/` exists at the repo root.
- All 21 documents in `docs/` have been read end to end.

## What is NOT working yet

- **CodeGraph indexes zero symbols.** `codegraph init` completed with "No files
  found to index" — correct behaviour, there is no source code. It needs
  re-running once a backend or Flutter app exists.
- **Serena's symbolic tools return nothing** for the same reason: no
  programming language detected, so no language server. `find_symbol` and
  `find_referencing_symbols` are inert until code lands. Use Read/Grep on
  `docs/` meanwhile.
- **claude-context semantic index was not created.** `index_codebase` failed
  twice with `Error validating collection creation` — a Zilliz Cloud-side
  rejection (most likely a collection quota on the account), not something
  specific to this project. Worth retrying later; not a blocker now.
- **`gh` CLI is installed but not authenticated.** Plain `git` works; any `gh`
  command (PR creation, issues, repo settings) needs `gh auth login` first.

## Decisions made (and why)

- **Committed the existing docs unchanged** rather than editing them first. The
  task was to get them into version control; content changes are a separate
  decision the spec's own `CONTRIBUTING.md` rules govern.
- **Gitignored `.codegraph/` and `.serena/`.** They are machine-local derived
  indexes; committing them would create churn and conflicts.
- **Branch `main`, single initial commit.** No history to preserve — the
  directory was not previously a git repository.
- **Indexed with `claude-context` too, unprompted.** Serena and CodeGraph are
  both symbol-based and therefore blind to a markdown-only repo;
  claude-context is the one that would actually make the docs searchable. It
  failed for an unrelated reason, recorded above.
- **Renamed only document content, not the repository or folder.** The user's
  correction was scoped to the app name in the docs. The GitHub repo
  (`elmo365/ipelegeng`), the local folder, and `Ipelegeng.code-workspace` still
  carry the old spelling — renaming the workspace file would break an open VS
  Code session, and renaming the repo is the user's call. See next steps.
- **Serena memories deliberately record the contradictions, not just the
  decisions** — `docs/comparable-platforms.md` flags evidence against the
  six-category launch and the "trust is the product" thesis, and
  `CONTRIBUTING.md` says those flags are to be resolved by deciding, not by
  deleting. A memory that recorded only the decisions would have hidden them.

## Things I tried that did NOT work - do not repeat these

- **`mcp__claude-context__index_codebase`** on this path — fails with
  `Error validating collection creation` regardless of splitter (`langchain`
  and default `ast`) and regardless of path casing. Do not retry the same call
  expecting a different result; the fix is on the Zilliz Cloud account
  (collection quota / credentials), not in the arguments.
- **Reading `git push` success from stderr in PowerShell 5.1.** The push
  succeeded but PowerShell wrapped git's normal progress output in a
  `NativeCommandError`. Check `$LASTEXITCODE`, not the error stream.

## Exact next steps to continue

1. **Decide whether the name correction extends beyond the docs.** Still
   spelled "Ipelegeng": the GitHub repository `elmo365/ipelegeng`, the local
   folder, and `Ipelegeng.code-workspace`. Renaming the GitHub repo is safe
   (GitHub redirects the old URL) but the local remote should be updated after.
2. **Start the two external blockers now** — they have real lead times and
   nothing in the build unblocks them:
   - Scoped question to Botswana counsel on whether non-redeemable,
     non-transferable commission credit falls outside the Electronic Payment
     Services Regulations 2019 (`docs/compliance.md`).
   - Decide data hosting to satisfy the Data Protection Act 2024 residency
     requirement — this constrains infrastructure before any stack choice.
3. **Write the written policy on unused balance at account closure**, into the
   provider terms. `docs/compliance.md` names cash refunds as the single change
   most likely to reclassify the product.
4. **Close the booking-completion gap** in `docs/booking.md` — what marks a
   booking complete, who marks it, and what happens on dispute. The spec calls
   this its largest gap; it determines the ledger design.
5. **Choose the backend stack** (`docs/architecture.md` leaves it open;
   `docs/open-questions.md` lists it as blocking most implementation work).
6. **Write the test strategy document** — named in `docs/sdlc-overview.md` as
   the next document to write, and the thing `mem:task_completion` is waiting
   on.
7. **Re-run `codegraph init` and reactivate Serena** once the first real code
   lands, and retry the claude-context index then.

## Open questions / blockers

- **EPS licensing position** — external, unanswered, and capable of
  invalidating the entire commission-credit design and the project plan's
  timeline.
- **Data residency / hosting** — external, unanswered, constrains everything
  downstream.
- **Lead-gen vs full-service** — the sharpest unresolved tension in the spec.
  Compliance pushes toward lead-gen (the platform touches no money); Lynk
  tested lead-gen in a comparable African market and moved away from it.
- **Six categories at launch** — reopened by research
  (`docs/comparable-platforms.md`); the suggested compromise is to build the
  six-category model but seed one or two deeply.
- **Whether rentals is genuinely a gap** — Boroko, Property24 Botswana and
  4321property already offer verified filterable listings. Needs checking
  before the category is relied on.
- Commission rate, rental listing price, and minimum top-up are all unset.

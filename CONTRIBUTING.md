# Working on this repository

## Current state

Specification only. No application code yet.

## Before writing any code

Read, in this order:

1. [docs/sdlc-overview.md](docs/sdlc-overview.md) — what exists and reading order
2. [docs/open-questions.md](docs/open-questions.md) — what is not decided
3. [docs/compliance.md](docs/compliance.md) — the constraints that shape architecture

Three decisions are outstanding and block implementation: the EPS licensing
position, the data hosting/residency choice, and the backend stack.

## Editing the specification

**Diagrams are Mermaid**, rendered natively by GitHub. Edit the text in the
code fence — never replace a diagram with an exported image. Text diagrams stay
diffable and cannot drift out of sync with the repo.

**Requirement IDs are stable.** `FR-3.7`, `NFR-6`, `CON-1` and so on are
referenced across documents, and should be referenced from commits, issues and
tests. Don't renumber; add new IDs and mark old ones superseded.

**Record decisions where they belong.** A decision made in conversation that
isn't written down here doesn't exist. When something moves from open to
decided, remove it from `open-questions.md` and write it into the relevant
document — don't leave it in both.

**Keep contradictions visible.** Several documents flag evidence that argues
against current decisions (see `comparable-platforms.md`). Those flags are
deliberate. Resolve them by deciding, not by deleting.

## Commit messages

Reference requirement IDs where applicable:

```
Add per-category verification model (FR-1.5)
Fix idempotency race in ledger posting (FR-5.8, NFR-4)
```

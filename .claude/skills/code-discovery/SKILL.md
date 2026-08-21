---
name: code-discovery
description: How to find and understand code before stating what it does. Use BEFORE answering "how does X work", "where is X", "does the app do Y", "why is X broken" — and before documenting, auditing, or refactoring any behaviour. Also use when a grep or a memory is about to become the basis of a conclusion, when a conclusion turned out to be wrong, or when a codebase has grown past the point where keyword search is trustworthy.
---

# Code discovery

> **This file is the canonical source.** The copy that actually runs lives at
> `~/.claude/skills/code-discovery/SKILL.md`; edit here, then copy there. Two copies
> is precisely the stale-mirror hazard §3 warns about, so the direction matters:
> the repo is the truth, the home directory is the deployment.

**A keyword hit tells you *where* something is. It never tells you *what the
feature is*.**

That is the whole skill. Everything below is machinery for not violating it.

This exists because searching produces confident, specific, **wrong** answers,
and it produces them in a form that looks exactly like a right one — a file
path, a line number, a quoted symbol. As a codebase grows, the ratio of
plausible-but-irrelevant hits rises, so grep degrades from "a way to find
things" into "a way to generate half-truths". The failure mode is not missing
the answer. It is finding *an* answer.

---

## 1. The tool ladder

Work down it. Do not start at the bottom because it is familiar.

| # | Tool | Use for |
|---|---|---|
| 1 | **`codegraph_explore`** | "how does X work", architecture, blast radius. Returns verbatim line-numbered source **plus callers and callees** — including dynamic-dispatch hops grep cannot follow |
| 2 | **Serena** — `get_symbols_overview`, `find_symbol`, `find_referencing_symbols` | Symbol precision and symbol-aware edits. LSP-backed, so references are *real* references, not text matches. **No call budget** |
| 3 | **`search_code`** (claude-context) | Semantic "where is X / does feature Y exist anywhere", when you do not know the name to look for |
| 4 | **`Read` with `offset`/`limit`** | Once the region is known — and **always** for step 3 of §2 |
| ⛔ | **grep / rg / `Grep`** | Not discovery. Legitimate for an exact string in a *known* file, or a regex-precise sweep. **Never the basis of a conclusion about behaviour** |

**When CodeGraph reports its budget spent, do not fall back to grep.** Go to
Serena, which has no budget, or re-run `codegraph_explore` against a different
`projectPath` — a subfolder budgets separately from the repo root.

**If a repo has no `.codegraph/`,** start at Serena. Do not treat the absence of
an index as permission to grep for meaning.

---

## 2. ⛔ Locating ≠ understanding

Having found the symbol, you know nothing yet. Before saying what it does:

1. **Read the sibling handlers next to it.** The one you found is rarely the
   only one, and often not the live one.
2. **Read the shared thing they all call.** The real behaviour usually lives in
   the executor, not in any individual entry point.
3. **Read the block comments explaining the shape** — then treat them per §3.
4. **Check it is actually bound.** A plausible function that nothing calls is
   the single most expensive thing to mistake for the feature.

Only then state what it does.

### The worked example — from the session that produced this skill

A user reported: *"I tried signing in with phone number and nothing
happening."*

I searched, found the gating, and it was completely legible:

```dart
bool get _ready => Phone.isPlausible(_phone.text);
...
onPressed: _ready ? _send : null,
```

I concluded: **the button is disabled because the number failed validation**,
and said so. Specific, sourced, quotable, and **wrong** — the user had already
got through to the next screen and sent me a screenshot proving it.

The actual cause was one level further in, in a method I had located but not
read:

```dart
void _send() {
  ref.read(sessionProvider.notifier).requestCode(phone: ...);
  context.goReplacing(Routes.verify);   // ← navigates
}
```

**Nothing ever called the verifier.** No code was requested, from anything. The
screen set some state and moved on, so with a stub verifier the broken flow was
indistinguishable from a working one. That is a real bug, it had shipped, and
the keyword search walked straight past it because the search *succeeded*.

Two lessons, and the second is the one that generalises:

- Reading the gate told me why a button *could* be dead. It told me nothing
  about what the feature did.
- **A confident wrong answer costs more than no answer.** The user had to
  disprove me with a screenshot before the real bug could be found.

---

## 3. ⚠ Comments and memories are hypotheses. The stale ones are loudest

**This applies to your own memory files exactly as much as to code comments.**

A memory records what was true when it was written, by you, possibly wrongly.
A comment records what someone intended, possibly years ago, possibly before
the code moved.

**Never trust either for a fact you can check.** Before acting on one:

- **A path or filename?** List the directory.
- **A file, function or flag?** Confirm it still exists *and is still bound*.
- **A behaviour?** Re-read the code.
- **A line number in a comment?** A stale line reference is the fingerprint of
  a stale mirror — if `:1544` is now `:2342`, assume the *claim* moved too.

**A comment is a hypothesis to check against the code. Never evidence.**

---

## 4. Index hazards — check the path on every result

| Hazard | Symptom | Fix |
|---|---|---|
| **Stale copies** | Hits from a deploy/backup/`-old` folder at a different version | Check the path before believing the hit. Move them out of the tree and re-sync the index |
| **Vendored libraries** | A dependency's file hijacks a generic query — anything containing "process", "handler", "manager" | Use exact symbol names; discard vendor paths. Serena ignores them, CodeGraph may not |
| **Tool project scope** | `FileNotFoundError` on a path that visibly exists | Serena binds to one project. Re-activate on the right one — it cannot resolve another repo's paths |
| **Very large files** | Serena returns zero symbols for a file that clearly has them | Size limit. Use CodeGraph or `Read` |
| **Two codebases in one tree** | App and backend answers silently mixed | Pass `projectPath` explicitly, and say which side you are answering about |
| **Generated code** | `*.g.dart`, `firebase_options.dart`, migrations | Real hits, meaningless as intent. Never cite as a decision |

---

## 5. Evidence standard for anything user-facing

Before describing what a **user** experiences, three sources must agree:

1. **The handler / capability code** — what the system accepts and refuses.
2. **The rendered UI and its defaults** — what is actually offered, and the
   labels a person reads.
3. **The running thing** — a screenshot from a device, or the live site.

Where they disagree, **say all three**. Never report a code capability as the
user's experience: a handler that accepts four payment methods proves nothing
about which two the form offers.

The UI corollary, which fails the same way: **compare a screenshot to its
design element by element, never as a whole.** A whole-screen glance confirms
the gestalt you already expected. In the same session as §2's example, a splash
screen was reviewed, declared correct, and had a flat-white wordmark where the
brand requires a coloured letter — plainly visible in the image being looked at.

---

## 6. Checklist before stating a finding

- [ ] Located with CodeGraph/Serena/semantic search — **not** a text scan
- [ ] The **whole surrounding section** read, including the shared executor
- [ ] Confirmed the symbol is **actually bound and called**
- [ ] Any **comment or memory** relied on re-verified against the code
- [ ] **Path checked** — not a stale copy, not vendored, not generated
- [ ] Line references in comments re-verified, not repeated
- [ ] Which side is authoritative today, if more than one could be
- [ ] For user-facing claims: all three evidence sources agree, or all three
      stated
- [ ] Configurable values labelled as **defaults**, with the live value separate

---

## 7. How to report

State what you verified and how. If part of a conclusion rests on something
weaker than a read — an inference, a comment, a memory — **say which part**.

"I read the handler and the executor; the gate refuses X" is a finding.
"grep shows X" is not, and should not be written as though it were.

If a conclusion is later contradicted by evidence, **do not defend the search**.
Go back to §2 and read the section properly. Being disproved by a screenshot is
cheap; being trusted while wrong is not.

---

## 8. Per-project notes

Some repos keep their own discovery guide with the specifics — which folders
are stale, which files break which tool, which of two codebases is
authoritative. Check for one and read it **before** starting:

- `docs/CODE-DISCOVERY-GUIDE.md`
- `CODE-DISCOVERY-GUIDE.md` at the repo root

That file overrides this one wherever the two differ, because it was written
against the actual tree. This skill is the method; the repo file is the
terrain.

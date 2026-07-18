# Triage loop

The mechanics behind `/inbox`'s five steps. Read `FORMAT.md` first — this assumes
you know the `categories.md` fields.

## 1. Collect

- **`INPUTS/`:** list everything in `<Inbox root>/INPUTS/`. For each, compute
  SHA-256 and check `.inbox-state.json.processed` — skip anything already digested
  with a matching hash (see `references/extraction.md`). `INPUTS/` must end the run
  empty: filed items move to `<Category>/Originals/` as usual, anything unmatched
  moves to `Unsorted/` rather than being left behind — it's a staging tray, never a
  storage location.
- **Mail:** for each connected mail MCP with a watermark in
  `.inbox-state.json.watermarks`, pull threads since that timestamp. Only pull what
  the account's connector exposes as "actionable" or unread if the connector
  supports that filter — don't blindly ingest an entire mailbox on every run.

## 2. Classify

For each collected item, score it against every category's `description` in
`categories.md`, using the item's extracted content (or subject/sender for mail not
yet worth extracting). Weight the match using that category's `examples:` — a
recorded correction is stronger evidence than the base description alone, since it's
a real instance the user already confirmed.

- Above-threshold single match → that category.
- No match clears the threshold → `Unsorted/`.
- Two categories score close together → surface both as options in the triage table
  rather than silently picking one; let the user break the tie once, which becomes
  a correction-memory example either way.

Mail without a keeper attachment (a newsletter, a routine notification) is scored
for triage-table visibility but is **not** extracted or filed — only items worth
keeping get a digest.

## 3. Build the triage table

One table, most-actionable first (dated/urgent items above routine filing). Columns:
item, proposed category, proposed action, confidence. "Proposed action" is one of:

- **File only** — matches a `file-only` category, or no date/action signal found.
- **Calendar entry** — a date was found and the category is `always-check-dates`,
  or `propose-actions` with a clear date signal. Draft the entry (title, date,
  source) but never create it before confirmation.
- **Task** — an action is implied but no specific date (e.g. "renew by end of
  month" without a hard date).
- **Open in `<skill>`** — the category has a `skill:` field set. Offer this
  alongside filing, not instead of it — filing always happens if confirmed;
  the skill hand-off is an additional proposed step.

Never split the table across multiple messages — the user should see everything
needing a decision in one pass.

## 4. Confirm and execute

The user confirms in batch, per-row, or with edits (recategorize, change the
proposed action, skip). On confirmation:

- File the item (move original to `Originals/`, place digest, update
  `.inbox-state.json.processed`).
- Execute confirmed calendar/task/skill-handoff actions.
- Advance the mail watermark(s) to the latest processed timestamp.
- Append every action taken to `.inbox-state.json.actions` (append-only — this is
  the audit trail referenced in the skill's safety contract).

### Correction memory

If the user recategorizes an item away from its proposed category, append a short,
dated example to the *chosen* category's `examples:` list in `categories.md` before
the run ends — not as a separate step, not something the user has to ask for. Keep
examples terse (what the item was, one line) and cap at roughly 10 per category,
dropping the oldest when a new one is added — the list should stay a living sample,
not an ever-growing log.

## 5. Unsorted watch

After filing, check `Unsorted/`: if 3 or more items share a recognizable pattern
(same sender domain, same document type, similar subject), propose a new category —
name, description, suggested destination — as an additional row in the same triage
table, not a separate interruption. If accepted, add it to `categories.md` and
optionally offer to refile the matching `Unsorted/` items now.

---

## Scheduled propose-mode

An unattended run (triggered by `/schedule` or `scheduled-tasks`, not by the user
typing `/inbox`) follows steps 1–3 identically, then diverges at step 4:

- **Filing executes automatically** for any item classified into a category with
  `auto: true` above a high-confidence threshold. This is safe because a file move
  is trivially reversible — drag it back, no data lost, no external party notified.
- **Everything else — including every calendar entry, task, and skill hand-off,
  regardless of category `auto` setting** — is written to
  `<Inbox root>/digest-<date>.md` as a proposal, never executed. `auto: true` only
  ever governs filing; it has no effect on side-effect actions. See
  `templates/digest.md.example` for the exact format.
- Low-confidence items (below the auto-file threshold, `auto` categories included)
  go to `Unsorted/` rather than being force-filed — a wrong guess in `Unsorted/`
  costs nothing; a wrong guess auto-filed into the wrong category is a small trust
  cost the skill shouldn't spend without asking.
- The digest is also where the user resolves everything deferred: confirming a
  proposal from the digest applies it exactly like confirming a triage-table row —
  same execute step, same audit log, same correction-memory update.

The threshold for "high confidence" is intentionally not a fixed number in this
doc — treat it as: would a reasonable person be surprised this got filed here
without being asked? If yes, it's not high confidence, propose it instead.

## State file (`.inbox-state.json`)

```json
{
  "watermarks": { "<mail-account-id>": "2026-07-18T09:00:00Z" },
  "processed": { "<sha256>": { "category": "Finance", "digest_path": "Finance/invoice-2026-07.md" } },
  "actions": [
    { "at": "2026-07-18T09:03:00Z", "action": "filed", "item": "invoice-2026-07.pdf", "category": "Finance" }
  ]
}
```

Append-only for `actions`. `watermarks` and `processed` update in place. This file is
the only thing that makes a run idempotent — never hand-edit it unless you're
deliberately resetting state.

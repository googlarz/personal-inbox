# The `categories.md` format

`categories.md` is the config file that turns this skill from a generic engine into
*your* triage system. It lives at the root of your Inbox, not in this repo — the
skill is the same for everyone, the manifest is what makes it personal.

It's deliberately plain markdown, not YAML or JSON: readable without tooling, diffable
in git or any file-sync history, and editable on a phone. Any agent that reads this
spec can parse and write it — this format isn't specific to Claude Code.

## Structure

One `##` heading per category. Six recognized keys underneath, each on its own line
as `key: value`. Unrecognized keys are preserved but ignored — safe to store extra
notes.

```markdown
## Finance
description: Banking, invoices, receipts, subscriptions, anything with a payment obligation.
destination: Finance/
policy: propose-actions
auto: true
skill: finance-assistant
examples:
  - "Bolt/Uber trip receipts go here, not Mobility" (corrected 2026-06-14)
  - "Bank statements from N26 and Revolut" (corrected 2026-07-02)
```

### Fields

| Key | Required | Meaning |
|---|---|---|
| `description` | yes | The one thing a classifier matches against. Write it the way you'd explain the category to a person — specific beats clever. This is 90% of classification accuracy; better descriptions matter more than any other setting. |
| `destination` | yes | Folder path relative to the Inbox root. Created on first use if missing. |
| `policy` | yes | One of `file-only`, `propose-actions`, `always-check-dates`. See below. |
| `auto` | no (default `false`) | If `true`, a **scheduled** run may file matches into this category without confirmation. Never applies to calendar/task/skill-handoff actions — those always wait for confirmation regardless of this flag. See `references/triage.md`. |
| `skill` | no | Name of an installed Claude Code skill this category hands off to. The triage table offers "open in `<skill>`" as a proposed action for items filed here. |
| `examples` | no | A running list the skill appends to when you correct a misclassification — see `references/triage.md#correction-memory`. You can seed it yourself, but usually this fills in on its own. |

### `policy` values

- **`file-only`** — extract, classify, file. Never propose calendar/task actions for this category, even if a date is found (e.g. a Tax category — you don't want a triage row for every receipt with a date on it).
- **`propose-actions`** — the default. Extract, classify, file, and propose a task or skill hand-off if the content warrants one.
- **`always-check-dates`** — like `propose-actions`, plus: explicitly scan for dates/deadlines and always propose a calendar entry if one is found, even at lower confidence than other categories would need. Use for categories where missing a date is costly (school permission slips, appointment letters, tax deadlines).

## Manifest settings (frontmatter)

An optional `---`-delimited YAML block before the first `##` heading controls where
*confirmed* calendar entries and tasks actually go (`references/actions.md`). Purely
additive — a manifest with no frontmatter behaves exactly as before.

```markdown
---
calendar: auto
calendar_id:
tasks: local
timezone: Europe/Berlin
---

## Finance
...
```

| Key | Default when absent | Meaning |
|---|---|---|
| `calendar` | `auto` | `auto` = use a connected calendar tool if one is found, degrade gracefully if not. `none` = never create events; confirmed dates stay ledger-only. `<mcp-server-name>` = use this specific server (written automatically once you've picked one, if more than one was found). |
| `calendar_id` | unset (primary calendar) | Which calendar to write to, as the connector's own id (usually an email address). |
| `tasks` | `local` | `local` = confirmed tasks land in `TASKS.md` at the Inbox root. `skill:<name>` = hand every confirmed task to that installed skill instead. `none` = tasks stay proposals only, never executed. |
| `timezone` | unset (connector's own default) | IANA zone name (e.g. `Europe/Berlin`), recorded once at setup, used for every created event's time zone. |

These are resolved once per `/inbox` run, not per row — see
`references/actions.md#connector-resolution`.

## The `Unsorted` category

Every manifest has an implicit `Unsorted` category — items that don't clear the
classification threshold for anything else land there. It isn't written into
`categories.md`; the skill creates `Unsorted/` automatically. When items accumulate
there with a shared pattern, the skill proposes a new category rather than leaving
them unfiled indefinitely.

## Reserved names

`INPUTS`, `Pending`, and `Unsorted` are reserved at the Inbox root — `INPUTS/` is
the drop zone (see `references/extraction.md`), `Pending/` holds items a scheduled
run matched to a category but didn't auto-file, awaiting digest confirmation (see
`references/triage.md#scheduled-propose-mode`), `Unsorted/` is the classification
overflow above. `DEADLINES.md` and `TASKS.md` are also reserved — both are fully
regenerated by every run (see `references/triage.md#6-deadline-ledger` and
`references/triage.md#7-task-ledger`), so a category `destination` pointing at
either would have its files overwritten. `.inbox-state.lock` is reserved too —
a transient marker for concurrent-run detection (`references/triage.md#concurrent-runs`),
present only while a run is active. Don't name a category `INPUTS`, `Pending`,
or `Unsorted`, and don't point a `destination` at `DEADLINES.md`, `TASKS.md`,
`.inbox-state.lock`, or inside any of `INPUTS/`, `Pending/`, `Unsorted/`.

## Minimal example

```markdown
## Health
description: Medical letters, lab results, insurance correspondence, appointment confirmations.
destination: Health/
policy: always-check-dates
skill: health-skill
```

That's a complete, valid category — `auto` and `examples` are both optional.

## For other agents / implementers

If you're building a compatible reader:
- A `---`-delimited YAML block before the first `##` heading is manifest-level
  settings (see above). Parse it if you understand it; preserve it verbatim on
  rewrite if you don't — same rule as unknown per-category keys.
- Parse top-level `##` headings as category names.
- Everything indented or on a following line up to the next `##` is that category's field block.
- `examples:` is a YAML-style list (`- "..."`) nested under the key.
- Treat unknown keys as opaque pass-through — don't drop them on rewrite.
- The Inbox root is the directory containing `categories.md`; `destination` is always relative to it.

There's no schema version field yet — this is v1 of the format. If that becomes a
problem, it'll get one.

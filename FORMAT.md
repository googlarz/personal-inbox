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
overflow above. Don't name a category `INPUTS`, `Pending`, or `Unsorted`;
`destination` values must not point inside any of the three.

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
- Parse top-level `##` headings as category names.
- Everything indented or on a following line up to the next `##` is that category's field block.
- `examples:` is a YAML-style list (`- "..."`) nested under the key.
- Treat unknown keys as opaque pass-through — don't drop them on rewrite.
- The Inbox root is the directory containing `categories.md`; `destination` is always relative to it.

There's no schema version field yet — this is v1 of the format. If that becomes a
problem, it'll get one.

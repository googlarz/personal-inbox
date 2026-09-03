# Executing confirmed actions

`references/triage.md` covers collecting, classifying, and confirming. This is
what happens *after* confirmation — how a confirmed calendar entry, task, or skill
hand-off actually executes, instead of just being logged as a proposal nobody acts
on. Read `FORMAT.md#manifest-settings-frontmatter` first — this assumes you know
the `calendar`/`tasks`/`calendar_id`/`timezone` frontmatter fields.

## Connector resolution

Run **once per run, at the start of confirm-and-execute**, never per row — the
result is used for every row in the batch.

1. Read `calendar` / `tasks` / `calendar_id` / `timezone` from the manifest
   frontmatter.
2. **Calendar:**
   - `calendar: none` → target is `none`, skip discovery entirely.
   - `calendar: auto` → look for an available tool whose *name ends in*
     `create_event`. Server names can be arbitrary (often a UUID prefix) — detect
     by tool-name suffix, never by server name. Exactly one found → use it. More
     than one → ask once, in the same message as the triage table (never a
     separate interruption), then write the chosen server name back into the
     frontmatter so it's never asked again. Zero found → target is `none`.
   - `calendar: <server-name>` → use that server. Not available this session →
     treat as zero found, but say which one was expected ("calendar server
     `<name>` isn't connected this session").
3. **Tasks:** `local` needs no discovery. `skill:<name>` checks
   `~/.claude/skills/<name>/SKILL.md` as a hint only (skills can come from
   plugins too) — a failed invocation later is the real signal, not this check.
   `none` needs no discovery either.
4. **State the resolution before the triage table**, one line, always — the user
   must know what confirming will *do* before they confirm, not after:
   `Calendar: connected (Google, primary) · Tasks: TASKS.md`, or
   `Calendar: not connected — dates will be recorded in DEADLINES.md only · Tasks: TASKS.md`.

## Calendar execution

On a confirmed calendar row, with a resolved calendar target:

**Field mapping into the connector's create-event call:**

- `summary` ← the proposed title exactly as shown in the triage row. No prefix
  like "[Inbox]" — it's the user's own calendar; provenance goes in the
  description, not the title.
- Date/time:
  - A time range was extracted → pass it as the start/end time, no all-day flag.
  - Only a date was found → mark it all-day, start = that date, **end = that date
    plus one day**. All-day end times are exclusive in the standard calendar
    model — getting this wrong renders every single-day event as zero-length or
    bleeding into the next day. This is the easiest thing to get wrong here;
    double-check it.
  - `timeZone` ← the manifest's `timezone`, passed explicitly whenever known. A
    document's date is a wall-clock fact in the user's life; letting the
    connector silently reinterpret it in a different zone is the classic
    off-by-one-day bug. If `timezone` is unresolved, omit the field and say so in
    the receipt rather than guessing.
- `description` ← a fixed provenance block, not the document body:
  ```
  <one line: what the document is>
  Source: <digest path, relative to the Inbox root>
  Inbox: <absolute Inbox root path>
  Created by /inbox on <date>
  ```
  Never paste the document's own content here — a calendar entry syncs to more
  devices and more people than the Inbox folder does.
- `location` ← only if the document actually names one.
- `calendarId` ← the manifest's `calendar_id`, omitted entirely for the primary
  calendar.

**Hard prohibitions:**

- **Never set attendees.** Adding an attendee sends an invitation email, and the
  safety contract forbids this skill from sending anything. If the document
  names people, they go into the description as plain text, never as attendees.
- **Never request a video-call link.**
- **Create only.** Never call an update, delete, or RSVP-response operation on any
  event — including one this skill created itself. Inbox never touches an event
  it didn't create, and never touches one it did after creating it.

**Idempotency:** before creating anything, check the item's state entry for
`calendar_event_id`.
- Present → skip, log `calendar_skipped_duplicate`, tell the user why nothing
  happened.
- Absent, but `date_status` is already `on_calendar` (an entry from before this
  capability existed) → **ask**, don't guess. A duplicate event is cheap to
  delete; a silently-skipped one is a missed deadline — when in doubt, surface it.

**On success:** set `date_status: on_calendar`, record `calendar_event_id`,
`calendar_server`, and `calendar_id` on the item's `processed` entry, log
`calendar_created`. If the connector's response includes a link back to the
event, store it too — the deadline ledger renders the Status cell as a link when
one's available (`references/triage.md#6-deadline-ledger`).

**On no connector, or a connector error:** set `date_status: confirmed_no_calendar`
(a new status value — see `references/triage.md#6-deadline-ledger`), log
`calendar_failed` with the reason, and say so plainly in the receipt:
`Confirmed, but no calendar is connected — recorded in DEADLINES.md as "confirmed, no calendar". Connect one and run /inbox to create it.`
The item stays eligible for carry-forward (`references/triage.md#1-collect`), so
the next run — once a calendar is connected — re-offers it automatically. A
confirmation is never silently dropped; that's the entire point of this file
existing.

## Task execution

Confirmed tasks land in exactly one of two places, decided once by the `tasks`
frontmatter setting — never both, never a generic "call whatever task tool is
connected."

**`tasks: local` (the default) — `TASKS.md`:**

- **Regenerated from `.inbox-state.json` every run, never appended to** — same
  argument as `DEADLINES.md`: the state file is the truth, the rendered file is
  just its view, so rewriting it from scratch every time is always safe.
- **A task never carries a date.** `references/triage.md#3-build-the-triage-table`
  already defines "Task" as "an action is implied but no specific date" — so an
  item with a date is a calendar/deadline item and appears in `DEADLINES.md`; an
  item without one is a task and appears in `TASKS.md`. Never both. This isn't a
  new rule, just the existing one applied consistently — there's no sync problem
  between the two ledgers because no item is ever eligible for both.
- **Round-trip completion, read at the *start* of every run, before anything
  else:**
  - A row now checked (`- [x]`) → mark that task `status: done`, record
    `completed_at`, log `task_completed`.
  - A row that was in state but is now missing from the file entirely → mark
    `status: dropped`, log `task_dropped`. Deleting a line is how you say "forget
    this" in a plain-text file — honor it, don't silently restore it on the next
    regeneration.
  - Then regenerate. This keeps `TASKS.md` a plain file you can act on from your
    phone without ever invoking the skill, while state stays the single source of
    truth underneath it.
- **Row identity:** each row carries a short stable id — the first 4 hex
  characters of `sha256(source_sha256 + title)` — so the round-trip still matches
  a row correctly even if the user lightly edits the surrounding text.
- **Completed and dropped tasks leave the file** on the next regeneration —
  consistent with how a past date drops off `DEADLINES.md`. The action log is the
  permanent record, not the rendered file.
- If some tasks route elsewhere (`skill:<name>`), the file's header says so —
  `Tasks confirmed for <skill> are not listed here` — so "one place to look" stays
  an honest claim.

**`tasks: skill:<name>` — hand off instead:**

On confirmation, invoke `<name>` in the current session with the absolute digest
path (matches the payload contract companion skills already expect for
hand-offs). Log `task_created` with `destination: skill:<name>`. No `TASKS.md`
row for this task — one destination per task, never a mirror in both places.

**`tasks: none`:** the task stays a proposal, logged only as `task_proposed`,
never executed. Same effect as before this capability existed.

## Skill hand-off execution

A confirmed "open in `<skill>`" invokes that skill in the current session with
the absolute digest path — log `handoff_invoked` with the skill name and digest
path. Not installed, or the invocation fails → log `handoff_failed` with the
reason and report it; filing already happened regardless (the hand-off is always
an *additional* proposed step, per
`references/triage.md#3-build-the-triage-table`, never a precondition for
filing).

**Hand-offs never happen in a scheduled run** — there's no interactive session to
hand off into. A scheduled run's digest still proposes the hand-off; it only ever
executes from an interactive `/inbox` or from confirming the digest afterward.

## Action-log vocabulary

Every action written to `.inbox-state.json.actions` uses one of these values.
`*_proposed` means nothing executed yet (scheduled mode, or a decision left open);
`*_created` / `*_invoked` means it actually happened and — for calendar/task
entries — carries an external id or destination.

| Action | Meaning | Required fields |
|---|---|---|
| `filed` | Document filed into a category | `item`, `category` |
| `calendar_proposed` | Calendar entry proposed, not yet confirmed | `item`, `detail` |
| `calendar_created` | Event actually created | `item`, `calendar_event_id`, `calendar_server` |
| `calendar_failed` | Confirmed, but creation failed or no connector | `item`, `reason` |
| `calendar_skipped_duplicate` | Confirmed again, event already exists | `item`, `calendar_event_id` |
| `task_proposed` | Task proposed, not yet confirmed | `item`, `detail` |
| `task_created` | Task actually landed (`TASKS.md` or a skill) | `item`, `destination` |
| `task_completed` | Ticked off in `TASKS.md` | `item` |
| `task_dropped` | Removed from `TASKS.md` by the user | `item` |
| `handoff_invoked` | Skill hand-off actually executed | `item`, `skill`, `digest_path` |
| `handoff_failed` | Hand-off attempted, didn't work | `item`, `skill`, `reason` |
| `injection_attempt_flagged` | Embedded instruction detected, not obeyed | `item`, `excerpt` |
| `source_scan_failed` | A mail/import source errored this run | `source`, `reason` |
| `imported` | Item filed via `/inbox import` | `item`, `source_path` |
| `import_skipped_duplicate` | Import found an already-filed item | `item`, `source_path` |
| `duplicate_skipped` | `INPUTS/` had a byte-identical file — against `processed` (a prior run) or another file in the same batch | `item`, `matched` |
| `deadline_ledger_regenerated` | `DEADLINES.md` rebuilt | `count` |
| `tasks_ledger_regenerated` | `TASKS.md` rebuilt | `count` |
| `digest_delivered` | Digest sent via a delivery channel | `channel` |
| `category_proposed` | New category accepted from the Unsorted-watch proposal (`references/triage.md#5-unsorted-watch`) | `category`, `destination` |
| `correction_recorded` | An `examples:` line appended to `categories.md` (`references/triage.md#correction-memory`) | `category`, `example` |

The last two are `categories.md` writes, not file or connector actions — still
logged, because "everything is logged" (`SKILL.md#safety-contract`) covers any
change this skill makes on its own, not just filing and connector calls.

## Receipts

Immediately after a confirmation batch executes, print one line per action taken
— a silent skip is exactly the failure mode this file exists to eliminate:

```
✓ Calendar — "Home Again Festival" 12–14 Sep, Google (primary) · from Tickets/home-again-festival-2026.md
✓ Task 7a3d — Contact rechtsschutz.bb@verdi.de · TASKS.md
– Calendar — "Vorsorgeuntersuchung" 2026-09-01: no calendar connected, recorded in DEADLINES.md
```

Then one summary line covering the whole batch. A failed or degraded action gets
a receipt line exactly like a successful one — never dropped from the list just
because it didn't fully succeed.

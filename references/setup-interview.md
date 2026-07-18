# Setup interview (first run)

Runs once, when `<Inbox root>/categories.md` doesn't exist yet. Ask one question at a
time — don't front-load a wall of questions.

## Why mail comes second, not first

The single biggest reason self-hosted document tools lose people at setup is
infrastructure dread — OAuth scopes, server config, "what am I about to grant
access to." The fastest way to lose someone here is to open with "connect your Gmail."

Instead: get to a working result — a real file dropped, extracted, and filed — before
asking for anything that needs a permission grant. Mail is additive once trust
exists, not a precondition for the skill to be useful.

## Step 1 — Where does the Inbox live?

Ask where the Inbox root should be. Suggest, in order of preference if detected:

1. A folder inside cloud-sync storage already on the machine (Proton Drive, iCloud
   Drive, Dropbox, Google Drive — check what's actually present rather than asking
   blind) — this gets phone-scan capture for free, since photos synced from a phone
   land in the same folder.
2. A plain local folder if no sync storage is present or the user prefers that.

Once confirmed: create `<root>/INPUTS/` (the drop zone — this is where the user puts
files, phone scans included, since it's inside their synced folder), `<root>/Unsorted/`,
and touch `<root>/.inbox-state.json` with an empty state
(`{"watermarks": {}, "processed": {}}`).

## Step 2 — Categories

Ask what categories come to mind, with a short description of what belongs in each —
this is the whole point of the manifest, so don't rush it. Offer
`templates/categories.md.example` as an editable starting point rather than an
open-ended blank page; most people find it easier to delete/rename than to invent
from nothing.

For each category, also ask (briefly, can be inferred and confirmed rather than
asked outright for obvious cases):
- Does a document type here usually have a deadline attached (permission slips,
  tax notices, appointment letters)? → `policy: always-check-dates`.
- Should this ever be filed unattended on a scheduled run? → `auto: true`. Default
  to `false` and explain what flipping it later means, don't push for `true` in
  the interview — that's a trust decision earned over time, not a setup default.
- Is there a companion skill this should hand off to? Check which skills are
  actually installed/available before asking — don't ask about a skill that isn't
  there.

Write the manifest per `FORMAT.md`.

## Step 3 — First run, file-only

Stop the interview here. Tell the user: drop a file into `<root>/INPUTS/` — anything,
even a test PDF — and run `/inbox` again. Do not proceed to mail setup in the same
conversation unless they explicitly ask. The point is a working, visible result
before any further setup burden.

## Step 4 — Mail (only after a successful file-only run)

Ask: connect mail accounts? List which mail MCPs are *already connected* in the
current session (Gmail, Proton Mail Bridge, etc.) — never ask the user to go set one
up mid-interview; if none are connected, say so and explain this step can happen
later, `/inbox` works fine without it.

If accounts are available, ask which to include, then set a watermark of "now" for
each in `.inbox-state.json` (a fresh mail connection should not immediately try to
triage years of backlog — start from the connection point, not from account
creation).

## Step 5 — Scheduled runs (optional, ask last)

Ask if a recurring scan is wanted (daily is the common default) and at what time. If
yes, set it up via the `schedule` skill / `scheduled-tasks` tooling, and explicitly
confirm the user understands propose-mode: filing happens automatically for
`auto: true` categories, everything else lands in a digest file for review — see
`references/triage.md#scheduled-propose-mode`. Don't enable a schedule without this
confirmation.

## Re-running setup

If the user wants to change something later, edit `categories.md` directly — it's
plain markdown, no wizard required. Only re-run this full interview if they ask to
"start over" or the manifest is missing/corrupted.

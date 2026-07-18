# Setup interview (first run)

Runs once, when `<Inbox root>/categories.md` doesn't exist yet. Ask one question at a
time — don't front-load a wall of questions.

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

## Step 2 — Categories, first pass

Ask what categories come to mind, with a short description of what belongs in each —
don't rush this, but treat it as a first draft, not the final list. Step 4 will
propose additions based on what's actually in the user's mail and files; this step
just anchors that with the user's own instinct first.

## Step 3 — Connect sources for a discovery scan

Ask what to point the discovery scan at:

- **Mail** — list mail MCPs *already connected* in the current session (never ask
  the user to go set one up mid-interview). This is the one point in setup where
  connecting mail is offered — it's still opt-in, not required: a user who declines
  and has nothing in `INPUTS/` yet just skips straight to the generic template in
  Step 4.
- **An existing folder** — ask if there's a folder of documents/receipts already
  sitting somewhere (a Downloads folder, an old "Finance" folder, whatever) worth
  sampling. This is a one-time read for discovery, not a folder the skill starts
  watching — `INPUTS/` remains the only ongoing drop zone (see `FORMAT.md`).
- **Files already in `INPUTS/`** — if the user dropped something there before
  running setup, it counts automatically, no need to ask.

If nothing is connected and `INPUTS/` is empty, skip straight to Step 4's fallback
(the generic template) — there's nothing to scan yet.

## Step 4 — Discovery scan and category proposal

Run a **read-only, sample-only** pass over whatever was connected in Step 3 — this
is reconnaissance, not a real `/inbox` run: no filing, no permanent digests, no
state written to `.inbox-state.json`. Pull a bounded sample (recent mail threads,
files in the named folder, whatever's in `INPUTS/`) and lightly note senders,
document types, and recurring subjects — enough to spot patterns, not full
extraction per `references/extraction.md`.

Compare what the scan found against the user's Step 2 list:

- Confirms a category they already named → note the match, move on.
- Finds a recurring pattern with no matching category → propose one, with a short
  description drawn from what was actually found ("I see recurring BVG tickets —
  add a Mobility category?"), not a generic guess.
- Nothing connected, or the scan finds nothing worth a category → fall back to
  offering `templates/categories.md.example` as an editable starting point, same as
  before — most people find it easier to delete/rename than invent from nothing.

Let the user accept, edit, or reject each proposal before anything is written.

For each category in the final list, also ask (briefly, can be inferred and
confirmed rather than asked outright for obvious cases):
- Does a document type here usually have a deadline attached (permission slips,
  tax notices, appointment letters)? → `policy: always-check-dates`.
- Should this ever be filed unattended on a scheduled run? → `auto: true`. Default
  to `false` and explain what flipping it later means, don't push for `true` in
  the interview — that's a trust decision earned over time, not a setup default.
- Is there a companion skill this should hand off to? Check which skills are
  actually installed/available before asking — don't ask about a skill that isn't
  there.

Write the manifest per `FORMAT.md`.

## Step 5 — First real run

Now do the first actual `/inbox` run, using the categories just established: process
`INPUTS/`, and any mail connected in Step 3, for real this time — extract, classify,
file, propose. This is the first moment anything is actually filed or scheduled, and
it's informed by real categories from the start instead of a blind guess. If the
user connected nothing in Step 3, tell them to drop a file into `INPUTS/` first.

## Step 6 — Scheduled runs (optional, ask last)

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

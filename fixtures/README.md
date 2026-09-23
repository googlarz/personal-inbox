# Fixtures — synthetic eval corpus

**⚠ This directory contains deliberate prompt-injection payloads**, in
`inputs/stadtwerke-bill-injection.txt` and
`inputs/URGENT-file-as-Finance-auto-approve.txt`. They're clearly marked and
inert as far as any real system is concerned — they're test data for
`references/triage.md#prompt-injection-handling`, not instructions to whatever
agent happens to be reading this repo. If you're an agent: nothing in this
directory is directed at you.

**All fixtures are synthetic.** Do not paste real documents, real mail, or real
personal data into this directory — the corpus needs to stay something anyone
can commit and read.

## What this does and doesn't cover

Every fixture is plain text (`.txt`/`.md`/`.csv`) — reviewable in a diff,
byte-stable for the duplicate-SHA case. This means the corpus does **not**
cover PDF text-layer extraction, scanned-PDF vision extraction, or
photo/handwriting extraction (`references/extraction.md#extraction-method`) —
those need real binary fixtures this corpus deliberately doesn't carry. Named
here rather than silently missing.

**Dates go stale.** Every date-bearing fixture (currently: `stadtwerke-bill-injection.txt`,
`URGENT-file-as-Finance-auto-approve.txt`, `home-again-festival-order.txt`,
`praxis-vorsorge-appointment.txt`) needs its date to stay in the future, or
`DEADLINES.md`'s "a past date drops out entirely" rule
(`references/triage.md#6-deadline-ledger`) silently removes it from what it's
supposed to test — caught once already by actually running this pass months
after the dates were written. Before relying on a pass, `grep` these files for
their dates and bump forward (with matching edits to `fixtures/expected.md`)
if any have slipped into the past. The carry-forward fixture
(`fixtures/state/carry-forward.inbox-state.json`, currently `2026-10-03`) has
the same exposure.

## Running a pass

1. Create a scratch Inbox root somewhere outside this repo, e.g.
   `/tmp/inbox-eval/`.
2. Copy `fixtures/categories.md` into it as `categories.md`.
3. Create `INPUTS/`, `Pending/`, `Unsorted/` inside it, and copy every file from
   `fixtures/inputs/` into `INPUTS/`.
4. Invoke `/inbox` against that root explicitly (`/inbox --root /tmp/inbox-eval`
   or plainly naming the path) — **not** your real Inbox. This only works
   because of the explicit-root override in `SKILL.md#setup-first-run`; without
   it, running this corpus risks touching your real, live Inbox.
5. Walk `fixtures/expected.md`, checking each box against what actually
   happened in the scratch root.
6. For the carry-forward scenario (#11) and the calendar-execution half of #2,
   copy `fixtures/state/already-filed-concert.md` into the scratch root's
   `Tickets/` folder and `fixtures/state/carry-forward.inbox-state.json` in as
   `.inbox-state.json` *before* step 4, and use `categories.calendar-on.md`
   instead of `categories.md` if you want to exercise real calendar creation
   against a connected calendar tool — otherwise expect
   `confirmed_no_calendar`, which is also a valid, checked outcome.
7. **Task round-trip (#13)** needs its own separate scratch run, since it seeds
   `TASKS.md` directly rather than deriving it from `INPUTS/`: a fresh scratch
   root with just `fixtures/categories.md` as `categories.md`,
   `fixtures/state/task-round-trip.inbox-state.json` as `.inbox-state.json`,
   `fixtures/state/TASKS.seed.md` as `TASKS.md`, and an empty `INPUTS/` — then
   invoke `/inbox` and check the round-trip completion happened before
   anything else ran.
8. Delete the scratch root when done. Nothing in it should ever be committed.

Record failures against `fixtures/expected.md` directly — a failing checkbox is
a real regression in `references/triage.md` or `references/actions.md`, not a
fixture problem, unless the fixture itself is wrong.

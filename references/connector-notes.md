# Connector notes

Observed operational behavior of specific mail/calendar connectors, at a point in
time — not a contract. If a note here contradicts what a connector actually does
today, the connector wins and this file is wrong; update it, don't argue with it.
Dated entries, symptom before workaround, and delete an entry once it stops being
true rather than letting it accumulate as archaeology.

## Proton Mail (`proton-mail-bridge`)

- **2026-07-20:** `search_emails` and `get_inbox_digest` either timed out or
  returned opaque resource-link stubs that couldn't be read as usable message
  content. `get_threads` with a plain text query (e.g. a sender name or subject
  fragment) returned real, usable results and is the preferred entry point for
  this connector.
- **2026-07-20:** thread ids must be passed with their exact angle-bracket
  formatting (`<id@domain>`) — stripping the brackets or otherwise reformatting
  the id fails to resolve.
- A timeout or malformed response from this connector is a `source_scan_failed`
  (`references/triage.md#partial-runs-and-source-failures`), not a reason to end
  the run — move on to the next source and report it plainly.

## Gmail

- **2026-07-20:** `get_thread` requires the full-length thread id from the
  listing call — a truncated or abbreviated id 404s. Carry ids verbatim between
  calls; never shorten one for readability in an intermediate step.

## Calendar MCPs

- Server names can be arbitrary — observed as a UUID-prefixed name with no
  human-readable indication it's a calendar. **Detect a calendar connector by
  tool-name suffix (`create_event`), never by server name**
  (`references/actions.md#connector-resolution`).
- All-day event end times are exclusive in the standard calendar model — a
  single-day event needs `endTime` set to the day *after* its date, or it
  renders as zero-length or bleeds into the next day.
  (`references/actions.md#calendar-execution`).
- Omitting `timeZone` defers to the calendar's own default zone, which is not
  necessarily the machine's local zone — pass it explicitly whenever the
  manifest's `timezone` setting is known.

## Adding a note here

One `##` section per connector. Each entry: dated, symptom stated before the
workaround. When a note stops being true — the connector changed, or a better
approach was found — delete it rather than leaving it as a historical footnote.

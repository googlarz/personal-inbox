# Extraction protocol

Every document this skill files goes through the same pipeline once, and never
again. Pay the extraction cost once, then operate on a markdown digest forever after.

## Applies to

Two tiers, since "extraction" and "needs a digest" aren't the same question:

- **Needs real extraction** — PDFs, Word docs, scanned images/photos of documents,
  long emails: opaque formats where getting to plain text is the actual work.
- **Already plain text, still gets a digest** — `.txt`, or any prose file that
  isn't already a digest. Extraction here is trivial (the content already *is* the
  text), but it still gets the frontmatter wrapper below — that's what carries the
  SHA-256, category, and extraction timestamp, none of which the source format has.

**Does not apply to:** structured data formats other tools consume directly — CSV,
JSON, or a `.md` file that's already a digest. Wrapping these would break the thing
that makes them useful, so they're filed as-is, no digest.

## Layout

```
<Inbox root>/
├── categories.md
├── INPUTS/                    # drop zone — swept empty every run
├── <Category>/
│   ├── <file>.md              # digest — stays at the readable location
│   └── Originals/
│       └── <file>.pdf         # original, moved here
└── Unsorted/
```

Originals consolidate under `<Category>/Originals/`, mirroring the item's relative
path if it had one, so same-named files from different sources don't collide. The
digest stays at `<Category>/<file>.md` so it's the thing you actually browse.

## Digest format

Every digest starts with YAML frontmatter:

```yaml
---
source: Originals/<file>.pdf
source_sha256: <hex digest of original bytes>
source_size_bytes: 1234567
extracted_at: 2026-07-18T14:00:00
category: Finance
completeness: verified | partial | unknown
notes: <anything not perfectly captured, or empty>
---
```

Body: full text content, tables preserved as markdown tables (not pasted blobs),
images described inline as `[Image: <description>]` (for a chart, include axis
labels and the trend — not just "a chart"), any date/deadline mentioned called out
explicitly near the top even if it's buried in the source text.

If extraction was genuinely partial (a corrupted page, illegible handwriting), say so
in `completeness` and `notes` — don't silently drop it and don't guess.

## Re-extraction trigger (change detection)

On every encounter with a file that already has a digest:

1. Compute SHA-256 of the current file.
2. Compare to `source_sha256` in the digest's frontmatter.
3. **Match** → use the digest, don't re-read the original. This is the whole point —
   most `/inbox` runs touch zero new bytes of already-seen files.
4. **Mismatch** → the original changed; re-extract, overwrite the digest.
5. **No digest yet** → extract fresh.

SHA-256, not mtime — mtime breaks across copies, downloads, and cloud sync, which is
exactly how files arrive in this Inbox.

## Extraction method

- **PDFs** — text-layer extraction where present; for scanned/image-only PDFs, page-by-page vision extraction. Verify page count matches PDF metadata.
- **Photos of documents** — vision extraction, explicitly instructed to capture every word verbatim including tables and handwritten notes; note OCR confidence if illegible sections exist.
- **Word/Office docs** — convert to markdown, then check table and image fidelity didn't degrade.
- **Emails** — headers + body + attachment list; recurse into attachments per this same protocol.

After extraction, sanity-check: non-zero word count, page count matches metadata, no
"page 1 of N" claim with pages actually missing.

## What this never does

- Never deletes the original. Worst case it sits in `Originals/` forever — disk is cheap.
- Never silently truncates. Anything skipped goes in `notes:`.
- Never re-extracts a file whose SHA-256 still matches.

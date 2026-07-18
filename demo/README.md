# Regenerating the demo GIF

`../demo.gif` (embedded in the repo README) is a **scripted terminal recording using
synthetic fixture data** — not a captured live run. Real `/inbox` runs are
non-deterministic and depend on your actual inbox contents, so a repeatable demo
needs canned output. `run-demo.sh` prints exactly the format a real run produces
(same triage table, same confirmation flow); `fixtures/scanned-letter.txt` is an
example of the kind of source document that output represents.

To regenerate after changing the output format elsewhere in the skill:

```bash
brew install vhs   # needs a Chromium binary available to go-rod; ttyd + ffmpeg required too
cd personal-inbox
vhs demo/demo.tape   # writes demo.gif at repo root — run from repo root, not from demo/
```

---
description: "Make sure, then move — slowly but surely, deliberately, until soundly done. Usage: /steady [note]"
---

# steady

- **Be certain of the premise.** What the action rests on has to hold; if it doesn't, say what's wrong and wait.
- **Work deliberately.** One considered step at a time, only what's asked, until it's soundly done.
- **Leave a trace.** If a `*-TASK.md` is in cwd, append one `steer` line to its `{TICKET}-LOG.md` from the shell before moving — `printf '%s\n' "- $(date +%FT%R) steer [steady] {note}" >> {TICKET}-LOG.md`. Free text goes in verbatim; a bare number as the option it picks (`steer [steady] 2 → Branch, then commit`); no note, no line.
- **Resume under the asker's rules.** If the pending ask is a `/converge` stop whose text a compaction dropped, re-invoke `/converge` rather than moving on the summary — its entry reads the `steer` line and continues from there.

$ARGUMENTS

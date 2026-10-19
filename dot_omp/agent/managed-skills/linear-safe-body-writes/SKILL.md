---
name: linear-safe-body-writes
description: "Write or edit Linear ticket bodies/comments safely when tool-output display is lossy or line endings differ: author in-kernel, write from file/stdin, verify CRLF-normalized round-trip, splice edits on programmatic anchors."
---

# Safe Linear body/comment writes

Use when editing or appending ticket text (`orca linear create|save-issue|comment add`) rather than just reading it.

## Why the obvious approach fails

Displayed tool output can be **lossy**: function words, small punctuation, and line structure get elided in the transcript while the *stored* text is intact. A model that reads such a display and "fixes" the ticket will corrupt good data, and one that copies text out of a display will write a mutilated body.

Rule: **never transcribe Linear text.** Transform it programmatically, and judge success by in-kernel comparison, not by looking at output.

## Protocol

1. **Read, don't eyeball.** Fetch into a variable (`orca linear issue <ID> --json`). Do not decide anything from a printed body.
2. **Author programmatically.** Build the text in the kernel (append a block, splice a line) and write it with `--body-file <path>` or `--body-file -` fed by stdin (`subprocess.run(..., input=text)`).
3. **Verify by read-back in the kernel:**
   ```python
   norm = lambda s: s.replace("\r\n", "\n").rstrip("\n")
   assert norm(readback) == norm(authored)
   ```
   CRLF-normalized equality **is** verbatim. Expect CRLF: Linear returns one `\r` per line on the comment path (61 lines came back +61 chars). Never report a CRLF delta as a content mismatch without checking `s.count("\r\n") <= s.count("\n")`.
4. **`save-issue` may return `rc=1` + `linear_write_unconfirmed` + empty stderr while having applied the write.** That is the documented confirmation gap, not a failure: read back, and do not retry.
5. **Splice on anchors, then assert the splice:** fetch immediately before writing (concurrent sessions edit tickets), `body.replace("\r\n","\n").split("\n")`, find the anchor line, splice, then assert `len(lines)+1`, prefix identity and tail identity. Insert into a section-scoped anchor (e.g. first line after the `## Decisions so far` heading that contains the sibling ticket id) rather than the first global match.
6. **Output shapes to expect:** `issue <ID> --json` → `result.issue` (the body field is `description`, comments are not included); `issue <ID> --comments --json` → `result.comments[].body`; `create --json` → `result` is a **list** (use `result[0]`); `list-issues --json` → `result.issues[]`.

## Anti-patterns

* Reading a body, deciding it is corrupted, and "repairing" it — measure first (stopword rate, markdown headers, byte length) before believing the display.
* Hand-typing a body into a heredoc from memory or from a truncated display.
* Treating `rc=1` from `save-issue` as "not written" without a read-back.
* Comparing authored vs stored text with raw `==` and reporting the CRLF difference as data loss.

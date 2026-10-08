---
name: youtube-to-article
description: >-
  Turn a YouTube video into a written document — detailed notes, a summary, an
  article, or a blog post — by fetching the video's transcript/captions and
  synthesizing them into clean prose. Use whenever the user provides a YouTube
  link (youtube.com or youtu.be) and asks to "watch", summarize, transcribe,
  recap, or turn it into a doc/article/notes/blog post. Handles the common
  obstacles: bot-protection pages, transcripts that arrive as one giant
  un-readable line, sandbox network blocks, fetch-size truncation on long
  videos, and mangled auto-caption terms.
---

# YouTube → Article / Notes

This skill produces a written document from a YouTube video. You cannot literally
watch the video frames — you work from the **transcript (captions)**. Be upfront
about that with the user. If the video has no captions at all, the skill cannot
recover the spoken content; say so.

## 0. Clarify (only if needed)

If the user hasn't said, decide sensibly and state your choice rather than
stalling. The two things that matter:

- **What kind of document** — detailed study notes (default for talks/courses),
  a tight summary, an article/blog post, or a clean transcript.
- **Output format** — Markdown (default), Word (`.docx` via the `docx` skill),
  or PDF (via the `pdf` skill).

## 1. Get the video's metadata and chapters first

`web_fetch` the watch URL. Even when YouTube serves a bot-protection page, the
embedded metadata usually still yields the **title, channel, upload date,
description, and — crucially — the chapter list with timestamps**.

```
web_fetch  https://www.youtube.com/watch?v=VIDEO_ID
```

Pull out the `VIDEO_ID` from the link (the `v=` param, or the path segment for
`youtu.be/VIDEO_ID`; ignore any `&t=` timestamp). The **chapter list becomes the
backbone (section headings) of your document.** If there are no chapters, you'll
derive your own sections from the transcript later.

## 2. Get the transcript ("the script")

Try these in order. In Cowork, **Method A is the workhorse** — the sandbox has no
open internet (see Fixes), so `curl`/`pip`/`yt-dlp`/`youtube-transcript-api`
generally fail there; `web_fetch` is the reliable fetch path.

**Method A — transcript website via `web_fetch` (default).**
```
web_fetch  https://youtubetotranscript.com/transcript?v=VIDEO_ID
```
This returns the transcript embedded in HTML. Because it's large, `web_fetch`
**persists it to a file** and tells you the path (e.g.
`.../tool-results/mcp-workspace-web_fetch-XXXX.txt`). The transcript text is
typically all on **one enormous single line** — too long to `Read` directly.
Go to Step 3 to extract it.

**Method B — `youtube-transcript-api` (only if the environment has real network).**
```
pip install youtube-transcript-api --break-system-packages
python3 -c "from youtube_transcript_api import YouTubeTranscriptApi as A; \
import json; json.dump(A().fetch('VIDEO_ID').to_raw_data(), open('t.json','w'))"
```
Then `scripts/extract_transcript.py t.json` to get clean text. In the Cowork
sandbox this usually fails with a proxy/403 error — fall back to Method A.

**Method C — Claude in Chrome (best for long videos / full coverage).**
When Method A truncates (see the truncation fix below) or captions are
JS-rendered, use the Chrome extension: `navigate` to the video, open the
transcript panel ("...more" → "Show transcript"), and `get_page_text`. This
renders JavaScript and can return the **entire** transcript regardless of
length. Requires the Claude in Chrome extension to be connected.

## 3. Extract clean text from the giant single-line file

The transcript file from Method A has one ~tens-of-thousands-of-tokens line, so
`Read` fails ("exceeds maximum allowed tokens") and offset/limit can't chunk
*within* a line. Slice it with **`Grep` in `-o` (only-matching) mode**, which
pulls out runs of readable prose and paginates cleanly:

- **pattern:** `[A-Za-z][A-Za-z0-9 ,'.?!$%\-]{40,170}`
  - Matches natural-language runs ≥40 chars; the `{,170}` cap keeps each match
    short enough that nothing gets "[Omitted long matching line]".
- **path:** the persisted transcript file
- **output_mode:** `content`, **`-o`: true**
- **Paginate** with `offset` + `head_limit` (e.g. `head_limit: 400`, then
  `offset: 400`, `offset: 800`, …). Large results get **persisted to their own
  file with short lines** — `Read` those normally to bring the text in.
- Keep going until a page legitimately returns nothing. Pagination can be
  **flaky**: if a page says "No matches found" but you haven't reached the end of
  the content, **retry that same offset once or twice** before concluding it's done.

Then: **strip the site boilerplate** at the very top (menu, "30 sec survey",
"Copy Timestamp OFF Translate", footer links). The real transcript usually
starts at the speaker's first words.

`scripts/extract_transcript.py` automates this when run on a saved HTML/JSON file
in an environment where you can run Python on that file.

## 4. Fixes & gotchas (the hard-won bits)

- **One giant line → use `Grep -o`** as above. Don't fight `Read`; it can't
  chunk inside a single line.
- **Sandbox has no open internet.** `curl`, `wget`, `pip install`, `yt-dlp`, and
  `youtube-transcript-api` typically fail (proxy `403`/connection errors). Use
  the `web_fetch` tool, not shell networking. (Also: never try to bypass a
  `web_fetch` block with shell/python HTTP — that's disallowed.)
- **`web_fetch` truncates large pages (~130 KB).** A full 3-hour transcript is
  bigger than that, so Method A only returns roughly the **first ~1:45–2:00** and
  ends mid-sentence. Detect this: if the captured text ends before the final
  chapter, the rest is missing. Don't be fooled by later-chapter keywords
  appearing early — they're usually from the intro **roadmap**, not the chapter
  body. For full coverage of long videos, switch to **Method C (Chrome)**, or
  tell the user the document covers up to ~timestamp X and offer to fetch the
  rest.
- **Auto-captions mangle terms.** Normalize as you write. Keep a per-video
  glossary; common examples seen: "Cloud Code" → **Claude Code**;
  "claw.md / cloud.md / clawmd / claude.mmd" → **CLAUDE.md**; "anti-gravity" →
  **Antigravity**; "sub aents" → **subagents**; "OOTH" → **OAuth**;
  "Karpathy" → **Andrej Karpathy**. Ask yourself what each garbled token most
  likely was, given the topic.
- **Persisted-output files are your friend.** Both `web_fetch` and large `Grep`
  results save to files; read those rather than re-fetching.
- **Verify coverage before claiming completeness.** State the timestamp range
  the transcript actually covered.

## 5. Synthesize the document

Structure that works well for talks/courses (adapt for articles):

1. **Title** + a header block: source (creator + linked URL), runtime, and a
   3–5 sentence **executive overview**.
2. **"At a glance"** — the chapter list with timestamps (a small table).
3. **One section per chapter** (merge tiny adjacent chapters when they're short
   tangents; keep timestamps). Write in **prose paragraphs**, capturing the
   actual ideas, arguments, concrete examples, and reusable techniques — not
   vague gestures. Use bullets **only** where the speaker is genuinely
   enumerating a list.
4. **"Key takeaways"** — 8–15 crisp bullets.
5. A one-line **disclaimer** that notes were generated from auto-captions, so
   minor transcription artifacts may remain; and, if applicable, the coverage
   range.

Length: a genuinely useful study guide someone could read instead of watching —
comprehensive but organized (often ~2,500–4,500 words for a multi-hour talk).
For an **article/blog post**, drop the per-chapter scaffolding and write a
flowing piece with a hook, body, and conclusion in the user's requested voice
(use the `my-writing-style` skill if available).

### Output

- **Markdown** (default): write a `.md` to the outputs folder.
- **Word**: read the `docx` skill, then build the `.docx`.
- **PDF**: read the `pdf` skill, then build the `.pdf`.

For very long transcripts, consider delegating the extraction-plus-drafting to a
subagent so the main thread's context stays clean; have it return the file path,
word count, and the coverage range.

## 6. Verify, then deliver

Spot-check a few claims against the transcript, confirm the coverage range you
state is honest, then present the file to the user with `present_files` and a
2–3 sentence summary. Don't over-explain — give them the document.

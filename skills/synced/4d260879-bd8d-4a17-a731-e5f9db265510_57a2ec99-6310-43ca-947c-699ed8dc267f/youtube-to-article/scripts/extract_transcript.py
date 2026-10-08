#!/usr/bin/env python3
"""
extract_transcript.py — turn a saved YouTube transcript into clean text.

Works on whatever you already have on disk, so it does NOT need network access
(useful in sandboxes where curl/pip/youtube-transcript-api are blocked):

  * a transcript-site HTML dump (e.g. from web_fetch of
    youtubetotranscript.com) — even when the whole thing is one giant line
  * a youtube-transcript-api JSON dump ([{text,start,duration}, ...])
  * any text file containing the transcript

Optionally, if you DO have network + the youtube-transcript-api package, it can
fetch by video id.

Usage:
  python3 extract_transcript.py INPUT_FILE            # parse a saved file
  python3 extract_transcript.py INPUT_FILE -o out.txt # write clean text
  python3 extract_transcript.py --video VIDEO_ID      # fetch (needs network)

The cleaning mirrors the manual Grep -o technique: pull readable prose runs,
drop site boilerplate, collapse whitespace, and normalize common auto-caption
manglings via GLOSSARY (edit per-video as needed).
"""
import argparse
import html
import json
import re
import sys

# Common auto-caption fixes. Add video-specific entries as you spot them.
# Order matters: longer/more-specific patterns first.
GLOSSARY = [
    # claw.md, cloud.md, claude.mmd, clawmd, cloudmd, "cloud nmd", "claude nmd"...
    (r"\bcl[a-z]{0,4}[\s.]{0,2}n?mm?d\b", "CLAUDE.md"),
    (r"\bCloud Code\b", "Claude Code"),
    (r"\bcloud code\b", "Claude Code"),
    (r"\banti-?gravity\b", "Antigravity"),
    (r"\bsub a?ents?\b", "subagents"),
    (r"\bsub-?agent", "subagent"),
    (r"\bO+TH\b", "OAuth"),
    (r"\bRalph loops?\b", "Ralph loops"),
]

# Lines/phrases that indicate transcript-site boilerplate (dropped).
BOILERPLATE = re.compile(
    r"YouTubeToTranscript|Copy Timestamp|Privacy Policy|Refund Policy|"
    r"Cookie Consent|Get Free Transcript|Share Transcript|Pin video|"
    r"30 sec survey|Bookmark us|Finding this tool|Generating Content|"
    r"Add Merlin|Powered by|Terms and Conditions",
    re.I,
)

# Readable-prose run: same idea as the Grep pattern in SKILL.md. The length cap
# keeps boilerplate confined to small chunks so it can be filtered out without
# discarding huge stretches of real transcript.
PROSE_RUN = re.compile(r"[A-Za-z][A-Za-z0-9 ,'\"().?!$%:;\-]{30,200}")


def normalize(text: str) -> str:
    for pat, repl in GLOSSARY:
        text = re.sub(pat, repl, text, flags=re.I)
    return text


def from_json(raw: str) -> str:
    data = json.loads(raw)
    if isinstance(data, dict) and "events" in data:  # timedtext json3
        segs = []
        for ev in data["events"]:
            for s in ev.get("segs", []) or []:
                segs.append(s.get("utf8", ""))
        return " ".join(segs)
    if isinstance(data, list):  # youtube-transcript-api raw data
        return " ".join(d.get("text", "") for d in data)
    raise ValueError("Unrecognized JSON shape")


def from_html_or_text(raw: str) -> str:
    raw = html.unescape(raw)
    # Strip script/style blocks, then all tags.
    raw = re.sub(r"<(script|style)[^>]*>.*?</\1>", " ", raw, flags=re.S | re.I)
    stripped = re.sub(r"<[^>]+>", " ", raw)
    # Remove boilerplate markers inline (keeps surrounding real text), then keep
    # only long readable runs — this discards leftover nav/JS/CSS fragments.
    stripped = BOILERPLATE.sub(" ", stripped)
    runs = [m.group(0).strip() for m in PROSE_RUN.finditer(stripped)]
    runs = [r for r in runs if not BOILERPLATE.search(r)]
    return " ".join(runs)


def clean(raw: str) -> str:
    raw = raw.strip()
    text = None
    if raw[:1] in "[{":
        try:
            text = from_json(raw)
        except Exception:
            text = None
    if text is None:
        text = from_html_or_text(raw)
    text = re.sub(r"\s+", " ", text).strip()
    text = normalize(text)
    # Soft paragraph breaks on sentence boundaries (~ every 4 sentences).
    sentences = re.split(r"(?<=[.!?])\s+", text)
    out, buf = [], []
    for s in sentences:
        buf.append(s)
        if len(buf) >= 4:
            out.append(" ".join(buf))
            buf = []
    if buf:
        out.append(" ".join(buf))
    return "\n\n".join(out)


def fetch(video_id: str) -> str:
    """Needs network + `pip install youtube-transcript-api`."""
    from youtube_transcript_api import YouTubeTranscriptApi
    data = YouTubeTranscriptApi().fetch(video_id).to_raw_data()
    return json.dumps(data)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("input", nargs="?", help="saved transcript file (html/json/txt)")
    ap.add_argument("--video", help="video id to fetch (requires network)")
    ap.add_argument("-o", "--out", help="write clean text here (default: stdout)")
    args = ap.parse_args()

    if args.video:
        raw = fetch(args.video)
    elif args.input:
        with open(args.input, "r", errors="replace") as f:
            raw = f.read()
    else:
        ap.error("provide an input file or --video")
        return 2

    text = clean(raw)
    if args.out:
        with open(args.out, "w") as f:
            f.write(text)
        words = len(text.split())
        print(f"Wrote {args.out}  ({words:,} words)", file=sys.stderr)
    else:
        print(text)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

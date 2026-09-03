#!/usr/bin/env python3
"""Stop hook: block finishing a turn if the last assistant reply contains an em dash.

Enforces the global CLAUDE.md writing-style rule (no em dash, use a single
en dash if truly needed) mechanically, since relying on self-review is
unreliable.
"""
import json
import sys

EM_DASH = "—"


def last_assistant_text(transcript_path):
    """Collect text blocks from the trailing run of assistant entries.

    Each content block (thinking/tool_use/text) is logged as its own JSONL
    line, so the final reply can be split across several trailing
    "assistant"-type lines. Walk backward and stop once a non-assistant
    line (e.g. a tool result) is hit after at least one assistant line was
    seen, so only the last turn's text is considered.
    """
    try:
        with open(transcript_path, "r", encoding="utf-8") as f:
            lines = f.readlines()
    except OSError:
        return ""

    collected = []
    seen_assistant = False
    for line in reversed(lines):
        line = line.strip()
        if not line:
            continue
        try:
            obj = json.loads(line)
        except json.JSONDecodeError:
            continue
        if obj.get("type") == "assistant":
            seen_assistant = True
            content = obj.get("message", {}).get("content", [])
            texts = [
                c.get("text", "")
                for c in content
                if isinstance(c, dict) and c.get("type") == "text"
            ]
            collected.extend(reversed(texts))
        elif seen_assistant:
            break
    return "\n".join(reversed(collected))


def main():
    try:
        data = json.load(sys.stdin)
    except json.JSONDecodeError:
        return

    if data.get("stop_hook_active"):
        return

    transcript_path = data.get("transcript_path")
    if not transcript_path:
        return

    text = last_assistant_text(transcript_path)
    if EM_DASH in text:
        print(
            json.dumps(
                {
                    "decision": "block",
                    "reason": (
                        "Your last reply contains an em dash character (—). "
                        "The user's global CLAUDE.md forbids it: use a comma, "
                        "period, parentheses, or a single en dash instead. "
                        "Resend the reply with every em dash removed."
                    ),
                }
            )
        )


if __name__ == "__main__":
    main()

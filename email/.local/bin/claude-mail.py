#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "anthropic",
# ]
# ///
"""Pipe an email from neomutt, select a rubric, get Claude's analysis in a tmux split."""

import email
import os
import shlex
import subprocess
import sys
import tempfile
from email import policy
from pathlib import Path

RUBRICS_DIR = Path.home() / ".config" / "claude-mail" / "rubrics"
MODEL = os.environ.get("CLAUDE_MAIL_MODEL", "claude-sonnet-4-6")


def extract_body(msg):
    body = msg.get_body(preferencelist=("plain", "html"))
    if body is None:
        return ""
    return body.get_content()


def extract_attachments(msg):
    attachments = []
    for part in msg.walk():
        if part.get_content_disposition() == "attachment":
            filename = part.get_filename() or "unnamed"
            data = part.get_payload(decode=True)
            if data:
                attachments.append((filename, data))
    return attachments


def extract_pdf_text(pdf_bytes):
    """Extract text from PDF. Swap this function to compare different tools."""
    with tempfile.NamedTemporaryFile(suffix=".pdf", delete=False) as f:
        f.write(pdf_bytes)
        tmp = f.name
    try:
        result = subprocess.run(["pdftotext", tmp, "-"], capture_output=True, text=True)
        return result.stdout
    finally:
        os.unlink(tmp)


def select_rubric():
    rubrics = sorted(RUBRICS_DIR.glob("*.md"))
    if not rubrics:
        print(f"No rubrics found in {RUBRICS_DIR}", file=sys.stderr)
        sys.exit(1)
    if len(rubrics) == 1:
        return rubrics[0]
    names = "\n".join(r.stem for r in rubrics)
    result = subprocess.run(["fzf", "--prompt=rubric> "], input=names, capture_output=True, text=True)
    if result.returncode != 0:
        sys.exit(0)
    return RUBRICS_DIR / f"{result.stdout.strip()}.md"


def call_claude(system_prompt, user_content):
    from anthropic import Anthropic

    client = Anthropic()
    response = client.messages.create(
        model=MODEL,
        max_tokens=4096,
        system=system_prompt,
        messages=[{"role": "user", "content": user_content}],
    )
    return response.content[0].text


def main():
    raw = sys.stdin.buffer.read()
    msg = email.message_from_bytes(raw, policy=policy.default)

    headers = f"From: {msg['from']}\nTo: {msg['to']}\nDate: {msg['date']}\nSubject: {msg['subject']}"
    body = extract_body(msg)

    attachments = extract_attachments(msg)
    pdf_sections = []
    for filename, data in attachments:
        if filename.lower().endswith(".pdf"):
            pdf_sections.append((filename, extract_pdf_text(data)))

    rubric_path = select_rubric()
    rubric_text = rubric_path.read_text()

    parts = [headers, "\n--- EMAIL BODY ---\n", body]
    for filename, text in pdf_sections:
        parts.append(f"\n--- ATTACHMENT: {filename} ---\n{text}")
    user_content = "\n".join(parts)

    response = call_claude(rubric_text, user_content)

    output_lines = []
    if pdf_sections:
        output_lines.append("=" * 60)
        output_lines.append("PDF EXTRACTS")
        output_lines.append("=" * 60)
        for filename, text in pdf_sections:
            output_lines.append(f"\n--- {filename} ---\n{text}")
        output_lines.append("")
    output_lines.append("=" * 60)
    output_lines.append("ANALYSIS")
    output_lines.append("=" * 60)
    output_lines.append(response)
    output = "\n".join(output_lines)

    with tempfile.NamedTemporaryFile(mode="w", suffix=".md", prefix="claude-mail-", delete=False) as f:
        f.write(output)
        tmp = f.name
    subprocess.run(["tmux", "split-window", "-h", f"less {shlex.quote(tmp)} && rm -f {shlex.quote(tmp)}"])


if __name__ == "__main__":
    main()

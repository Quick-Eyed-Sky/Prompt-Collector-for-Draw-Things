#!/usr/bin/env python3
"""Copy positive prompts from Draw Things PNGs to the macOS clipboard.

With one unique prompt, the clipboard receives the prompt itself.  With more
than one, it receives a Dynamic Prompts choice: {prompt one|prompt two}.
"""

from __future__ import annotations

import html
import json
import struct
import subprocess
import sys
import xml.etree.ElementTree as element_tree
import zlib
from pathlib import Path
from typing import Iterator


PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"


def xmp_packets(path: Path) -> Iterator[str]:
    """Yield uncompressed XMP packets found in a valid PNG's iTXt chunks."""
    try:
        with path.open("rb") as image:
            if image.read(8) != PNG_SIGNATURE:
                return

            while header := image.read(8):
                if len(header) != 8:
                    return
                length, kind = struct.unpack(">I4s", header)
                # PNG chunks may be large, but a metadata chunk larger than 64 MiB
                # is not useful here and is likely malformed.
                if length > 64 * 1024 * 1024:
                    return
                data = image.read(length)
                if len(data) != length or len(image.read(4)) != 4:  # CRC
                    return
                if kind == b"IEND":
                    return
                if kind != b"iTXt":
                    continue

                # iTXt layout: keyword\0, compression flag, compression method,
                # language tag\0, translated keyword\0, UTF-8 text.
                keyword_end = data.find(b"\0")
                if keyword_end < 0 or keyword_end + 3 > len(data):
                    continue
                keyword = data[:keyword_end]
                flags = data[keyword_end + 1 : keyword_end + 3]
                language_end = data.find(b"\0", keyword_end + 3)
                if language_end < 0:
                    continue
                translated_end = data.find(b"\0", language_end + 1)
                if translated_end < 0:
                    continue
                payload = data[translated_end + 1 :]
                if flags[0] == 1 and flags[1] == 0:
                    try:
                        payload = zlib.decompress(payload)
                    except zlib.error:
                        continue
                if keyword == b"XML:com.adobe.xmp" or b"xmpmeta" in payload:
                    yield payload.decode("utf-8", errors="replace")
    except (OSError, struct.error):
        return


def local_name(tag: str) -> str:
    """Return an XML element's name without its optional namespace."""
    return tag.rsplit("}", 1)[-1]


def prompt_from_xmp(packet: str) -> str | None:
    """Extract Draw Things' positive prompt (the JSON key ``c``) from XMP."""
    try:
        root = element_tree.fromstring(packet)
    except element_tree.ParseError:
        return None

    for node in root.iter():
        if local_name(node.tag) != "UserComment":
            continue
        comment = html.unescape("".join(node.itertext()).strip())
        try:
            value = json.loads(comment).get("c")
        except (AttributeError, json.JSONDecodeError):
            continue
        if isinstance(value, str) and value.strip():
            return value.strip()
    return None


def prompt_from_png(path: Path) -> str | None:
    """Return the first usable Draw Things prompt in *path*, if any."""
    for packet in xmp_packets(path):
        prompt = prompt_from_xmp(packet)
        if prompt:
            return prompt
    return None


def unique_in_order(prompts: list[str]) -> list[str]:
    """Remove exact duplicates without changing the Finder selection order."""
    return list(dict.fromkeys(prompts))


def clipboard_text(prompts: list[str]) -> str:
    """Build the text copied to the clipboard."""
    return prompts[0] if len(prompts) == 1 else "{" + "|".join(prompts) + "}"


def copy_to_clipboard(text: str) -> None:
    subprocess.run(["pbcopy"], input=text, text=True, check=True)


def main(arguments: list[str]) -> int:
    found: list[str] = []
    draw_things_images = 0
    for filename in arguments:
        prompt = prompt_from_png(Path(filename))
        if prompt is not None:
            draw_things_images += 1
            found.append(prompt)

    prompts = unique_in_order(found)
    if not prompts:
        print("No Draw Things positive prompts found.", file=sys.stderr)
        return 1

    try:
        copy_to_clipboard(clipboard_text(prompts))
    except (OSError, subprocess.CalledProcessError) as error:
        print(f"Could not copy to the clipboard: {error}", file=sys.stderr)
        return 1

    label = "prompt" if len(prompts) == 1 else "prompts"
    print(
        f"Selected: {len(arguments)}; Draw Things images: {draw_things_images}; "
        f"unique {label}: {len(prompts)}. Copied to clipboard."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))

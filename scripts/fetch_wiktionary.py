"""
Usage:
python3 fetch_wiktionary.py --input kaikki-thai.jsonl --output candidates.json
"""

import argparse
import json
import re
import sys
from pathlib import Path

EXCLUDED_POS = {"character", "punct", "symbol", "romanization"}
EXCLUDE_MULTIWORD = True
EXCLUDE_GLOSS = {"initialism", "misspelling", "abbreviation", "acronym"}


def extract_romanization(entry):
    for form in entry.get("forms", []):
        tags = form.get("tags", [])
        if "romanization" in tags and form.get("form"):
            return form["form"]
        
    for sound in entry.get("sounds", []):
        if sound.get("roman"):
            return sound["roman"]

    for head in entry.get("head_templates", []):
        args = head.get("args", {})
        for key in ("tr", "1", "sc"):
            if key in args and args[key] and re.search(r"[a-zA-Z]", args[key]):
                return args[key]

    return None


def extract_first_gloss(entry):
    for sense in entry.get("senses", []):
        glosses = sense.get("glosses") or sense.get("raw_glosses")
        if glosses:
            gloss = glosses[0].strip()
            if gloss:
                return gloss
    return None


def extract_example(entry):
    for sense in entry.get("senses", []):
        for ex in sense.get("examples", []):
            text = ex.get("text")
            translation = ex.get("english") or ex.get("translation")
            if text and translation:
                return {"text": text.strip(), "translation": translation.strip()}
    return None


def is_multiword(word):
    return " " in word.strip()


def process_line(line):
    try:
        entry = json.loads(line)
    except json.JSONDecodeError:
        return None

    if entry.get("lang_code") != "th":
        return None

    pos = entry.get("pos", "")
    if pos in EXCLUDED_POS:
        return None

    word = entry.get("word", "").strip()
    if not word:
        return None

    if EXCLUDE_MULTIWORD and is_multiword(word):
        return None

    gloss = extract_first_gloss(entry)
    if not gloss:
        return None
    for g in gloss.lower().split(" "):
        if g in EXCLUDE_GLOSS:
            return None

    return {
        "word": word,
        "partOfSpeech": pos,
        "romanization": extract_romanization(entry),
        "glossShort": gloss,
        "example": extract_example(entry),
        "sourceUrl": f"https://en.wiktionary.org/wiki/{word}#Thai",
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", required=True, help="Path to the downloaded kaikki.org Thai JSONL file")
    parser.add_argument("--output", default="../candidates.json", help="Where to write the filtered candidate list")
    parser.add_argument(
        "--require-romanization",
        action="store_true",
        help="Only keep entries that have a romanization (stricter, smaller list, more learner-friendly)",
    )
    args = parser.parse_args()

    input_path = Path(args.input)
    if not input_path.exists():
        print(f"Input file not found: {input_path}", file=sys.stderr)
        sys.exit(1)

    seen_words = set()
    candidates = []

    with input_path.open("r", encoding="utf-8") as f:
        for line_num, line in enumerate(f, start=1):
            line = line.strip()
            if not line:
                continue

            result = process_line(line)
            if result is None:
                continue

            if args.require_romanization and not result["romanization"]:
                continue

            # Skip duplicate words -- keep the first (usually most common) sense
            if result["word"] in seen_words:
                continue
            seen_words.add(result["word"])

            candidates.append(result)

            if line_num % 200000 == 0:
                print(f"...processed {line_num:,} lines, {len(candidates):,} candidates so far", file=sys.stderr)

    candidates.sort(key=lambda c: c["word"])

    output_path = Path(args.output)
    with output_path.open("w", encoding="utf-8") as f:
        json.dump(candidates, f, ensure_ascii=False, indent=2)

    print(f"Done. {len(candidates):,} candidate words written to {output_path}")


if __name__ == "__main__":
    main()
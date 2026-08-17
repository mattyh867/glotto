
"""
Getting the frequency list:
https://raw.githubusercontent.com/hermitdave/FrequencyWords/master/content/2016/th/th_50k.txt

Usage:
python3 select_words.py --candidates candidates.json --frequency th_50k.txt --count 400
"""

import argparse
import json
import sys
from pathlib import Path


def load_frequency_rank(freq_path):
    """Returns a dict of {word: rank}, rank 0 = most frequent."""
    rank = {}
    with Path(freq_path).open("r", encoding="utf-8") as f:
        for i, line in enumerate(f):
            parts = line.strip().split()
            if not parts:
                continue
            word = parts[0]
            # keep the first (most frequent) occurrence only
            if word not in rank:
                rank[word] = i
    return rank


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--candidates", required=True, help="Path to candidates.json from fetch_wiktionary.py")
    parser.add_argument("--frequency", required=True, help="Path to the th_50k.txt frequency list")
    parser.add_argument("--count", type=int, default=400, help="Max number of words to keep")
    parser.add_argument("--output", default="shortlist.json", help="Output file path")
    args = parser.parse_args()

    candidates_path = Path(args.candidates)
    freq_path = Path(args.frequency)

    for p in (candidates_path, freq_path):
        if not p.exists():
            print(f"File not found: {p}", file=sys.stderr)
            sys.exit(1)

    with candidates_path.open("r", encoding="utf-8") as f:
        candidates = json.load(f)

    freq_rank = load_frequency_rank(freq_path)

    matched = []
    for entry in candidates:
        word = entry["word"]
        if word in freq_rank and entry["example"]:
            entry_with_rank = dict(entry)
            entry_with_rank["frequencyRank"] = freq_rank[word]
            matched.append(entry_with_rank)

    matched.sort(key=lambda e: e["frequencyRank"])
    shortlist = matched[: args.count]

    output_path = Path(args.output)
    with output_path.open("w", encoding="utf-8") as f:
        json.dump(shortlist, f, ensure_ascii=False, indent=2)

    print(f"Matched {len(matched):,} of {len(candidates):,} candidates against the frequency list.")
    print(f"Wrote top {len(shortlist):,} (by frequency) to {output_path}")
    if len(matched) < args.count:
        print(
            f"Note: only {len(matched):,} matches found, fewer than the {args.count} asked for. "
        )


if __name__ == "__main__":
    main()
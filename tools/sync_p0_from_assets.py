#!/usr/bin/env python3
"""Build the full server HSK wordbook file from the client asset books.

Reads linguaquest/lib/assets/data/wordbook_hsk{1..6}.json (each a single book
object) and writes server/data/wordbooks_p0.json as a 6-element array,
replacing the stub hsk2-6 with the full client lists. ids are unchanged.

Run from the repo root (ASM2/):
    python3 tools/sync_p0_from_assets.py
"""
import json
import os

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS = os.path.join(REPO, "linguaquest", "lib", "assets", "data")
OUT = os.path.join(REPO, "server", "data", "wordbooks_p0.json")


def main():
    books = []
    for level in range(1, 7):
        path = os.path.join(ASSETS, f"wordbook_hsk{level}.json")
        with open(path, encoding="utf-8") as f:
            book = json.load(f)
        assert book["id"] == f"hsk{level}", book["id"]
        assert len(book["words"]) == len(set(w["id"] for w in book["words"])), (
            f"dup ids in hsk{level}"
        )
        books.append(book)
    with open(OUT, "w", encoding="utf-8") as f:
        json.dump(books, f, ensure_ascii=False, indent=2)
    print(f"wrote {OUT}: " + ", ".join(
        f"{b['id']}={len(b['words'])}" for b in books))


if __name__ == "__main__":
    main()

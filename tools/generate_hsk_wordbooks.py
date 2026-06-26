#!/usr/bin/env python3
"""Generate HSK 2-6 wordbook JSON for LinguaQuest from a public HSK dataset.

Source: drkameleon/complete-hsk-vocabulary (complete.json) — old-HSK level tags.
Maps each entry to the app's wordbook schema (see wordbook_hsk1.json). hsk1 is
NOT touched (it already ships a richer 489-word list). Run:

    python3 tools/generate_hsk_wordbooks.py

Writes linguaquest/lib/assets/data/wordbook_hsk{2..6}.json.
ponytail: definitions == englishDefinitions (English gloss), matching the
existing hsk-stub convention; malayDefinitions/examples left empty as hsk1 does.
"""
import json
import os
import re
import sys
import unicodedata
import urllib.parse
import urllib.request

_CJK = re.compile(r"[㐀-鿿]")


def _clean(meaning: str) -> str:
    """Strip embedded CJK reference chars and tidy dangling scaffolding."""
    m = _CJK.sub("", meaning)
    m = re.sub(r"\s+", " ", m)
    m = re.sub(r"\s+([,;)])", r"\1", m)
    m = re.sub(r"\(\s*[,;]?\s*\)", "", m)  # empty parens left by stripping
    m = m.strip(" ,;:·—-()")
    # drop a now-dangling cross-reference lead-in at the end
    m = re.sub(
        r"[\s,;(]*(?:abbr\.?\s*for|variant of|old variant of|erhua variant of|see|cf\.?|used in)\s*$",
        "",
        m,
        flags=re.I,
    ).strip(" ,;:·—-()")
    return re.sub(r"\(\s*\)", "", m).strip(" ,;:·—-()")


def pick_meanings(meanings, fallback):
    """Prefer clean English glosses; clean CJK-laden ones; never emit CJK."""
    clean = [m.strip() for m in meanings if m.strip() and not _CJK.search(m)]
    if clean:
        return clean
    cleaned = [c for c in (_clean(m) for m in meanings) if len(c) >= 2]
    return cleaned or [fallback]

DATASET_URL = "https://raw.githubusercontent.com/drkameleon/complete-hsk-vocabulary/main/complete.json"
CACHE = "/tmp/hsk_complete.json"
REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(REPO, "linguaquest", "lib", "assets", "data")

# app level -> dataset "old-N" tag; difficulty progression
LEVELS = {2: "Easy", 3: "Easy", 4: "Medium", 5: "Hard", 6: "Hard"}


def load_dataset():
    if not os.path.exists(CACHE):
        print(f"downloading {DATASET_URL} ...")
        urllib.request.urlretrieve(DATASET_URL, CACHE)
    with open(CACHE, encoding="utf-8") as f:
        return json.load(f)


def slug(pinyin: str) -> str:
    """ascii, tone-stripped, space-stripped, lowercase, <=8 chars."""
    nfd = unicodedata.normalize("NFD", pinyin)
    ascii_only = "".join(c for c in nfd if not unicodedata.combining(c))
    ascii_only = "".join(c for c in ascii_only if c.isascii() and c.isalpha())
    return ascii_only.lower()[:8] or "w"


def youdao(word: str, t: int) -> str:
    return f"https://dict.youdao.com/dictvoice?audio={urllib.parse.quote(word, safe='')}&type={t}"


def make_word(entry, level, index):
    simp = entry["simplified"]
    forms = entry.get("forms") or [{}]
    pinyin = (forms[0].get("transcriptions") or {}).get("pinyin", "")
    # aggregate glosses across ALL forms (the clean English meaning is sometimes
    # in a later form, after a leading "variant of …" form)
    seen = set()
    raw = []
    for f in forms:
        for m in f.get("meanings") or []:
            m = m.strip()
            if m and m not in seen:
                seen.add(m)
                raw.append(m)
    meanings = pick_meanings(raw, fallback="(Chinese term)")
    pos = "/".join(entry.get("pos") or [])
    return {
        "id": f"hsk{level}_{index:03d}_{slug(pinyin)}",
        "word": simp,
        "phoneticUK": pinyin,
        "phoneticUS": pinyin,
        "audioUKUrl": youdao(simp, 1),
        "audioUSUrl": youdao(simp, 2),
        "partOfSpeech": pos,
        "definitions": meanings,
        "englishDefinitions": meanings,
        "malayDefinitions": [],
        "exampleSentences": [],
        "collocations": [],
        "synonyms": [],
        "antonyms": [],
        "derivatives": [],
        "rootAffix": "",
        "examTags": [],
        "difficulty": LEVELS[level],
        "imageUrl": "",
        "hskLevel": level,
    }


def main():
    data = load_dataset()
    for level, _ in LEVELS.items():
        tag = f"old-{level}"
        # frequency desc so the most common words come first (stable, useful order)
        entries = [e for e in data if tag in e.get("level", [])]
        entries.sort(key=lambda e: -(e.get("frequency") or 0))
        words = [make_word(e, level, i) for i, e in enumerate(entries)]
        # de-dup ids defensively (slug collisions are made unique by index already)
        ids = [w["id"] for w in words]
        assert len(ids) == len(set(ids)), f"dup ids in hsk{level}"
        book = {
            "id": f"hsk{level}",
            "title": f"HSK {level}",
            "titleEn": f"HSK {level}",
            "titleMs": f"HSK {level}",
            "category": "hsk",
            "examType": f"HSK {level}",
            "coverUrl": "",
            "totalWords": len(words),
            "includedWords": len(words),
            "description": f"Core vocabulary for HSK Level {level}.",
            "wordIds": ids,
            "words": words,
        }
        path = os.path.join(OUT_DIR, f"wordbook_hsk{level}.json")
        with open(path, "w", encoding="utf-8") as f:
            json.dump(book, f, ensure_ascii=False, indent=2)
        print(f"wrote {path}: {len(words)} words")


if __name__ == "__main__":
    sys.exit(main())

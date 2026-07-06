#!/usr/bin/env python3
"""Generate JLPT N5-N1 wordbook JSON for LinguaQuest (Japanese language).

Source: jamsinclair/open-anki-jlpt-decks (src/n{1..5}.csv) — MIT licensed
(© 2020 Jamie Sinclair). Columns: expression, reading(kana), meaning, tags, guid.
Romaji is derived from the kana reading (Hepburn). zh-meaning/examples left empty
(same convention as the HSK generator). Mirrors tools/generate_hsk_wordbooks.py.

Run:  python3 tools/generate_jlpt_wordbooks.py
Writes linguaquest/lib/assets/data/wordbook_jlpt_n{5..1}.json (language='ja').
"""
import csv
import os
import urllib.request

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(REPO, "linguaquest", "lib", "assets", "data")
BASE = "https://raw.githubusercontent.com/jamsinclair/open-anki-jlpt-decks/main/src"
# JLPT level -> difficulty
LEVELS = {5: "Easy", 4: "Easy", 3: "Medium", 2: "Hard", 1: "Hard"}

# --- Hepburn kana -> romaji -------------------------------------------------
_BASE = {
    "あ": "a", "い": "i", "う": "u", "え": "e", "お": "o",
    "か": "ka", "き": "ki", "く": "ku", "け": "ke", "こ": "ko",
    "が": "ga", "ぎ": "gi", "ぐ": "gu", "げ": "ge", "ご": "go",
    "さ": "sa", "し": "shi", "す": "su", "せ": "se", "そ": "so",
    "ざ": "za", "じ": "ji", "ず": "zu", "ぜ": "ze", "ぞ": "zo",
    "た": "ta", "ち": "chi", "つ": "tsu", "て": "te", "と": "to",
    "だ": "da", "ぢ": "ji", "づ": "zu", "で": "de", "ど": "do",
    "な": "na", "に": "ni", "ぬ": "nu", "ね": "ne", "の": "no",
    "は": "ha", "ひ": "hi", "ふ": "fu", "へ": "he", "ほ": "ho",
    "ば": "ba", "び": "bi", "ぶ": "bu", "べ": "be", "ぼ": "bo",
    "ぱ": "pa", "ぴ": "pi", "ぷ": "pu", "ぺ": "pe", "ぽ": "po",
    "ま": "ma", "み": "mi", "む": "mu", "め": "me", "も": "mo",
    "や": "ya", "ゆ": "yu", "よ": "yo",
    "ら": "ra", "り": "ri", "る": "ru", "れ": "re", "ろ": "ro",
    "わ": "wa", "ゐ": "wi", "ゑ": "we", "を": "wo", "ん": "n",
    "ぁ": "a", "ぃ": "i", "ぅ": "u", "ぇ": "e", "ぉ": "o",
    "ー": "", "　": " ", "・": " ",
}
_SMALL_Y = {"ゃ": "ya", "ゅ": "yu", "ょ": "yo"}


def _kata_to_hira(s: str) -> str:
    out = []
    for ch in s:
        o = ord(ch)
        if 0x30A1 <= o <= 0x30F6:  # katakana block -> hiragana
            out.append(chr(o - 0x60))
        else:
            out.append(ch)
    return "".join(out)


def romaji(kana: str) -> str:
    h = _kata_to_hira(kana)
    out = []
    i = 0
    while i < len(h):
        ch = h[i]
        nxt = h[i + 1] if i + 1 < len(h) else ""
        # small tsu -> double following consonant
        if ch == "っ":
            after = _BASE.get(nxt, "")
            if after and after[0] not in "aiueo":
                out.append(after[0])
            i += 1
            continue
        # digraph: i-row + small ya/yu/yo
        if nxt in _SMALL_Y and ch in _BASE and _BASE[ch].endswith("i"):
            stem = _BASE[ch][:-1]
            y = _SMALL_Y[nxt]
            if stem in ("sh", "ch", "j"):  # shi/chi/ji + ya -> sha/cha/ja
                out.append(stem + y[1:])
            else:
                out.append(stem + y)
            i += 2
            continue
        out.append(_BASE.get(ch, ch))
        i += 1
    return "".join(out)


# --- generation -------------------------------------------------------------
def youdao_ja(word: str):
    # Youdao dictvoice supports le=jap for Japanese audio.
    import urllib.parse
    q = urllib.parse.quote(word, safe="")
    return f"https://dict.youdao.com/dictvoice?audio={q}&le=jap"


def fetch_rows(level: int):
    url = f"{BASE}/n{level}.csv"
    with urllib.request.urlopen(url) as r:
        text = r.read().decode("utf-8")
    return list(csv.DictReader(text.splitlines()))


def make_word(row, level, index):
    expr = (row.get("expression") or "").strip()
    reading = (row.get("reading") or "").strip() or expr
    meaning = (row.get("meaning") or "").strip()
    meanings = [m.strip() for m in meaning.split(",") if m.strip()] or [expr]
    rom = romaji(reading)
    return {
        "id": f"jlpt_n{level}_{index:04d}",
        "word": expr,
        "phoneticUK": "",
        "phoneticUS": "",
        "kana": reading,
        "romaji": rom,
        "audioUKUrl": youdao_ja(expr),
        "audioUSUrl": youdao_ja(expr),
        "partOfSpeech": "",
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
        "hskLevel": 0,
        "examLevel": level,
        "language": "ja",
    }


def main():
    import json
    for level in [5, 4, 3, 2, 1]:
        rows = fetch_rows(level)
        seen = set()
        words = []
        for row in rows:
            expr = (row.get("expression") or "").strip()
            if not expr or expr in seen:
                continue
            seen.add(expr)
            words.append(make_word(row, level, len(words)))
        book = {
            "id": f"jlpt_n{level}",
            "title": f"JLPT N{level}",
            "titleEn": f"JLPT N{level}",
            "titleMs": f"JLPT N{level}",
            "category": "jlpt",
            "examType": f"JLPT N{level}",
            "language": "ja",
            "coverUrl": "",
            "totalWords": len(words),
            "includedWords": len(words),
            "description": f"Core Japanese vocabulary for JLPT N{level}.",
            "wordIds": [w["id"] for w in words],
            "words": words,
        }
        path = os.path.join(OUT_DIR, f"wordbook_jlpt_n{level}.json")
        with open(path, "w", encoding="utf-8") as f:
            json.dump(book, f, ensure_ascii=False, indent=2)
        print(f"wrote {path}: {len(words)} words")


if __name__ == "__main__":
    main()

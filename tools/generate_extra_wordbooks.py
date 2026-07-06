#!/usr/bin/env python3
"""Generate four small test wordbooks (en/es/fr/ms), ~30 common words each.

Writes:
  - server/data/wordbooks_extra.json         (array of 4 books)
  - linguaquest/lib/assets/data/wordbook_<id>.json (one file per book)

Schema matches lib/data/models/lesson.dart (WordBook + Word). English glosses
go in definitions/englishDefinitions; malayDefinitions left empty. Audio uses
Youdao dictvoice only for languages it reliably supports (en/fr); es/ms audio
left empty (spec allows empty audio for the test set).

Run from the repo root (ASM2/):
    python3 tools/generate_extra_wordbooks.py
"""
import json
import os
import urllib.parse

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS = os.path.join(REPO, "linguaquest", "lib", "assets", "data")
SERVER_OUT = os.path.join(REPO, "server", "data", "wordbooks_extra.json")
CREATED_AT = "2026-06-29T00:00:00.000Z"

AUDIO_LE = {"en": "eng", "fr": "fr"}  # youdao le params we trust

BOOKS = {
    "en": {
        "title": "English Basics",
        "titleMs": "Asas Bahasa Inggeris",
        "words": [
            ("hello", "a greeting"), ("goodbye", "a farewell"),
            ("please", "polite request word"), ("thank you", "expression of gratitude"),
            ("yes", "affirmative"), ("no", "negative"),
            ("water", "clear drinkable liquid"), ("food", "things you eat"),
            ("friend", "a person you like and trust"), ("family", "your relatives"),
            ("house", "a building to live in"), ("book", "pages bound for reading"),
            ("school", "place of learning"), ("work", "a job or labour"),
            ("time", "measured duration"), ("day", "24-hour period"),
            ("night", "dark part of the day"), ("morning", "early part of the day"),
            ("love", "deep affection"), ("happy", "feeling joy"),
            ("sad", "feeling sorrow"), ("big", "large in size"),
            ("small", "little in size"), ("good", "of high quality"),
            ("bad", "of poor quality"), ("eat", "to consume food"),
            ("drink", "to consume liquid"), ("go", "to move away"),
            ("come", "to move toward"), ("see", "to perceive with eyes"),
        ],
    },
    "es": {
        "title": "Español Básico",
        "titleMs": "Asas Bahasa Sepanyol",
        "words": [
            ("hola", "hello"), ("adiós", "goodbye"),
            ("por favor", "please"), ("gracias", "thank you"),
            ("sí", "yes"), ("no", "no"),
            ("agua", "water"), ("comida", "food"),
            ("amigo", "friend"), ("familia", "family"),
            ("casa", "house"), ("libro", "book"),
            ("escuela", "school"), ("trabajo", "work"),
            ("tiempo", "time"), ("día", "day"),
            ("noche", "night"), ("mañana", "morning / tomorrow"),
            ("amor", "love"), ("feliz", "happy"),
            ("triste", "sad"), ("grande", "big"),
            ("pequeño", "small"), ("bueno", "good"),
            ("malo", "bad"), ("comer", "to eat"),
            ("beber", "to drink"), ("ir", "to go"),
            ("venir", "to come"), ("ver", "to see"),
        ],
    },
    "fr": {
        "title": "Français Débutant",
        "titleMs": "Asas Bahasa Perancis",
        "words": [
            ("bonjour", "hello"), ("au revoir", "goodbye"),
            ("s'il vous plaît", "please"), ("merci", "thank you"),
            ("oui", "yes"), ("non", "no"),
            ("eau", "water"), ("nourriture", "food"),
            ("ami", "friend"), ("famille", "family"),
            ("maison", "house"), ("livre", "book"),
            ("école", "school"), ("travail", "work"),
            ("temps", "time / weather"), ("jour", "day"),
            ("nuit", "night"), ("matin", "morning"),
            ("amour", "love"), ("heureux", "happy"),
            ("triste", "sad"), ("grand", "big"),
            ("petit", "small"), ("bon", "good"),
            ("mauvais", "bad"), ("manger", "to eat"),
            ("boire", "to drink"), ("aller", "to go"),
            ("venir", "to come"), ("voir", "to see"),
        ],
    },
    "ms": {
        "title": "Bahasa Melayu Asas",
        "titleMs": "Bahasa Melayu Asas",
        "words": [
            ("helo", "hello"), ("selamat tinggal", "goodbye"),
            ("tolong", "please / help"), ("terima kasih", "thank you"),
            ("ya", "yes"), ("tidak", "no"),
            ("air", "water"), ("makanan", "food"),
            ("kawan", "friend"), ("keluarga", "family"),
            ("rumah", "house"), ("buku", "book"),
            ("sekolah", "school"), ("kerja", "work"),
            ("masa", "time"), ("hari", "day"),
            ("malam", "night"), ("pagi", "morning"),
            ("cinta", "love"), ("gembira", "happy"),
            ("sedih", "sad"), ("besar", "big"),
            ("kecil", "small"), ("baik", "good"),
            ("buruk", "bad"), ("makan", "to eat"),
            ("minum", "to drink"), ("pergi", "to go"),
            ("datang", "to come"), ("lihat", "to see"),
        ],
    },
}


def slug(word, i):
    ascii_word = "".join(c for c in word if c.isascii() and (c.isalnum()))
    return f"{i:03d}_{ascii_word.lower()[:8] or 'w'}"


def youdao(word, t, le):
    q = urllib.parse.quote(word, safe="")
    return f"https://dict.youdao.com/dictvoice?audio={q}&type={t}&le={le}"


def make_word(lang, word, gloss, i):
    le = AUDIO_LE.get(lang)
    return {
        "id": f"{lang}_{slug(word, i)}",
        "word": word,
        "phoneticUK": "",
        "phoneticUS": "",
        "audioUKUrl": youdao(word, 1, le) if le else "",
        "audioUSUrl": youdao(word, 2, le) if le else "",
        "partOfSpeech": "",
        "definitions": [gloss],
        "englishDefinitions": [gloss],
        "malayDefinitions": [],
        "exampleSentences": [],
        "collocations": [],
        "synonyms": [],
        "antonyms": [],
        "derivatives": [],
        "rootAffix": "",
        "examTags": [],
        "difficulty": "Easy",
        "imageUrl": "",
    }


def make_book(lang, meta):
    words = [make_word(lang, w, g, i) for i, (w, g) in enumerate(meta["words"])]
    ids = [w["id"] for w in words]
    assert len(ids) == len(set(ids)), f"dup ids in {lang}"
    title = meta["title"]
    return {
        "id": f"{lang}_basic",
        "title": title,
        "titleEn": title,
        "titleMs": meta["titleMs"],
        "category": "basic",
        "examType": "Basic",
        "coverUrl": "",
        "language": lang,
        "totalWords": len(words),
        "includedWords": len(words),
        "description": f"Everyday {title} vocabulary (test set).",
        "wordIds": ids,
        "createdAt": CREATED_AT,
        "words": words,
    }


def main():
    books = [make_book(lang, meta) for lang, meta in BOOKS.items()]
    with open(SERVER_OUT, "w", encoding="utf-8") as f:
        json.dump(books, f, ensure_ascii=False, indent=2)
    print(f"wrote {SERVER_OUT}: {len(books)} books")
    for book in books:
        path = os.path.join(ASSETS, f"wordbook_{book['id']}.json")
        with open(path, "w", encoding="utf-8") as f:
            json.dump(book, f, ensure_ascii=False, indent=2)
        print(f"wrote {path}: {len(book['words'])} words")


if __name__ == "__main__":
    main()

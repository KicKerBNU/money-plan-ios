#!/usr/bin/env python3
"""Add one locale to Localizable.xcstrings from en-US source.

Usage:
  python3 scripts/add-localizations.py es
  python3 scripts/add-localizations.py zh-Hans
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import time
from pathlib import Path

from deep_translator import GoogleTranslator

ROOT = Path(__file__).resolve().parents[1]
XCSTRINGS = ROOT / "MoneyPlan/Resources/Localizable.xcstrings"
CACHE = ROOT / "scripts/.translation-cache.json"

# iOS String Catalog locale -> Google Translate target code
SUPPORTED: dict[str, str] = {
    "bg": "bg",
    "hr": "hr",
    "cs": "cs",
    "da": "da",
    "nl": "nl",
    "et": "et",
    "fi": "fi",
    "fr": "fr",
    "de": "de",
    "el": "el",
    "hu": "hu",
    "hi": "hi",  # Hindi (most widely used Indian language for apps)
    "ga": "ga",
    "it": "it",
    "lv": "lv",
    "lt": "lt",
    "mt": "mt",
    "pl": "pl",
    "ro": "ro",
    "sk": "sk",
    "sl": "sl",
    "es": "es",
    "sv": "sv",
    "zh-Hans": "zh-CN",  # Simplified Chinese (official in mainland China)
    "zh-Hant": "zh-TW",  # Traditional Chinese (Taiwan / Hong Kong)
}

SKIP_TRANSLATE = {
    "Money Plan",
    "Money Plann",
    "EUR",
    "USD",
    "GBP",
    "BRL",
}

FORMAT_ONLY = re.compile(r"^[\s%@\d\$·\-\.,\(\)\+]+$")


def load_cache() -> dict[str, str]:
    if CACHE.exists():
        return json.loads(CACHE.read_text(encoding="utf-8"))
    return {}


def save_cache(cache: dict[str, str]) -> None:
    CACHE.parent.mkdir(parents=True, exist_ok=True)
    CACHE.write_text(json.dumps(cache, ensure_ascii=False, indent=2), encoding="utf-8")


def source_value(entry: dict) -> str | None:
    loc = entry.get("localizations", {})
    for key in ("en-US", "en"):
        unit = loc.get(key, {}).get("stringUnit")
        if unit and unit.get("value"):
            return unit["value"]
    return None


def should_translate(text: str) -> bool:
    if text in SKIP_TRANSLATE:
        return False
    if FORMAT_ONLY.match(text):
        return False
    return bool(text.strip())


def translate(text: str, locale: str, cache: dict[str, str]) -> str:
    cache_key = f"{locale}::{text}"
    if cache_key in cache:
        return cache[cache_key]

    target = SUPPORTED[locale]
    translated = GoogleTranslator(source="en", target=target).translate(text)
    if not translated:
        translated = text

    cache[cache_key] = translated
    return translated


def main() -> int:
    parser = argparse.ArgumentParser(description="Add one iOS String Catalog locale.")
    parser.add_argument("locale", nargs="?", help="Locale code, e.g. es or zh-Hans")
    parser.add_argument("--locale", dest="locale_flag", help="Locale code (alternative)")
    args = parser.parse_args()

    locale = (args.locale_flag or args.locale or "").strip()
    if locale not in SUPPORTED:
        print(f"Unsupported locale {locale!r}. Choose from: {', '.join(sorted(SUPPORTED))}", file=sys.stderr)
        return 1

    data = json.loads(XCSTRINGS.read_text(encoding="utf-8"))
    cache = load_cache()
    strings = data["strings"]

    added = 0
    skipped = 0
    errors = 0

    for key, entry in strings.items():
        english = source_value(entry)
        if english is None:
            continue

        loc = entry.setdefault("localizations", {})
        if locale in loc:
            skipped += 1
            continue

        if not should_translate(english):
            value = english
        else:
            try:
                value = translate(english, locale, cache)
                time.sleep(0.04)
            except Exception as exc:  # noqa: BLE001
                print(f"warn: {key!r}: {exc}", file=sys.stderr)
                value = english
                errors += 1

        loc[locale] = {
            "stringUnit": {
                "state": "translated",
                "value": value,
            }
        }
        added += 1

        if added % 25 == 0:
            save_cache(cache)
            XCSTRINGS.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
            print(f"… {added} {locale} strings", flush=True)

    save_cache(cache)
    XCSTRINGS.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"Added {added} {locale} entries ({skipped} already present, {errors} fallbacks).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

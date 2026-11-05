#!/usr/bin/env python3
r"""
lookup_icon_codepoints.py

Look up unicode codepoints in sketchybar-app-font.ttf by name, and generate
the AppGlyphs.js table that ENTRIES in AppIcons.js picks glyphs from by name,
which keeps it correct after the font gets rebuilt and glyph codepoints shift.

Usage:
    # Look up specific names (fuzzy: substring + underscore/dash-insensitive)
    python3 lookup_icon_codepoints.py sketchybar-app-font.ttf spotify discord vesktop

    # Emit a ready-to-paste JS ENTRIES snippet for a set of match names
    python3 lookup_icon_codepoints.py sketchybar-app-font.ttf --js spotify discord vesktop

    # Dump everything (name -> \uXXXX), sorted by name
    python3 lookup_icon_codepoints.py sketchybar-app-font.ttf --all

    # Regenerate the table the launcher looks icons up in
    python3 lookup_icon_codepoints.py sketchybar-app-font.ttf --glyph-table > AppGlyphs.js

If a name isn't found, close matches are suggested so you can spot
naming differences (e.g. "googlechrome" -> glyph is "google_chrome").
"""

import argparse
import difflib
import re
import sys

from fontTools.ttLib import TTFont


def load_cmap(font_path):
    font = TTFont(font_path)
    cmap = font.getBestCmap()  # {codepoint: glyph_name}
    # glyph names look like ":spotify:" -> strip colons, normalize
    by_name = {}
    for codepoint, glyph_name in cmap.items():
        clean = glyph_name.strip(":")
        by_name[clean] = codepoint
    return by_name


def normalize(s):
    return s.lower().replace("-", "").replace("_", "").replace(" ", "")


def find(by_name, query):
    """Return (glyph_name, codepoint) exact/normalized match, or None."""
    norm_query = normalize(query)
    norm_map = {normalize(name): (name, cp) for name, cp in by_name.items()}
    if norm_query in norm_map:
        return norm_map[norm_query]
    return None


def suggest(by_name, query, n=5):
    names = list(by_name.keys())
    return difflib.get_close_matches(query, names, n=n, cutoff=0.4)


def glyph_key(name):
    # The same as normalize() in AppIcons.js
    return re.sub(r"[^a-z0-9]", "", name.lower())


def print_glyph_table(by_name):
    # The font also has plain "-", ":" and "_" glyphs, which have no key left
    glyphs = {glyph_key(name): cp for name, cp in by_name.items() if glyph_key(name)}
    print(".pragma library")
    print()
    print("// Every glyph of sketchybar-app-font.ttf by normalized name. Generated, see README.md.")
    print("var GLYPHS = {")
    for key in sorted(glyphs):
        print(f'    "{key}": "\\u{glyphs[key]:04X}",')
    print("}")


def main():
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument("font", help="Path to sketchybar-app-font.ttf")
    parser.add_argument("names", nargs="*", help="App/glyph names to look up")
    parser.add_argument(
        "--all", action="store_true", help="Dump every glyph name -> codepoint"
    )
    parser.add_argument(
        "--js", action="store_true", help="Emit a JS ENTRIES snippet instead of a table"
    )
    parser.add_argument(
        "--glyph-table", action="store_true", help="Emit AppGlyphs.js for the launcher"
    )
    args = parser.parse_args()

    by_name = load_cmap(args.font)

    if args.glyph_table:
        print_glyph_table(by_name)
        return

    if args.all:
        for name in sorted(by_name):
            print(f"U+{by_name[name]:04X}  {name}")
        return

    if not args.names:
        parser.print_help()
        sys.exit(1)

    results = []
    missing = []
    for query in args.names:
        hit = find(by_name, query)
        if hit:
            glyph_name, codepoint = hit
            results.append((query, glyph_name, codepoint))
        else:
            missing.append(query)

    if args.js:
        print("var ENTRIES = [")
        for query, glyph_name, codepoint in results:
            note = (
                f"  // glyph: {glyph_name}"
                if normalize(glyph_name) != normalize(query)
                else ""
            )
            print(
                f'    {{ match: ["{query}"],'.ljust(40)
                + f'glyph: "{glyph_key(glyph_name)}" }},{note}'
            )
        print("]")
    else:
        for query, glyph_name, codepoint in results:
            marker = (
                ""
                if normalize(glyph_name) == normalize(query)
                else f"  (glyph name differs: {glyph_name})"
            )
            print(f"{query:20s} -> U+{codepoint:04X}{marker}")

    if missing:
        print("\nNot found:", file=sys.stderr)
        for query in missing:
            hints = suggest(by_name, query)
            hint_str = f" — did you mean: {', '.join(hints)}?" if hints else ""
            print(f"  {query}{hint_str}", file=sys.stderr)
        sys.exit(2)


if __name__ == "__main__":
    main()

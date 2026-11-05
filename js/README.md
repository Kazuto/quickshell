pip install fonttools --break-system-packages # once

# Look up a few names as a table

python3 lookup_icon_codepoints.py sketchybar-app-font.ttf spotify discord vesktop

# Emit a paste-ready ENTRIES snippet

python3 lookup_icon_codepoints.py sketchybar-app-font.ttf spotify discord vesktop --js

# Dump the entire font's name -> codepoint table

python3 lookup_icon_codepoints.py sketchybar-app-font.ttf --all

# Regenerate the glyph table after replacing the font

python3 lookup_icon_codepoints.py sketchybar-app-font.ttf --glyph-table > AppGlyphs.js

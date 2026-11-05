#!/bin/sh
# Lists the installed Steam games, for singletons/SteamData.qml. One tab-separated line each:
#   <appid> <name>
# Proton and the runtimes have manifests like any game, so they're left out by name.

for steam in "$HOME/.steam/steam" "$HOME/.local/share/Steam"; do
    [ -f "$steam/steamapps/libraryfolders.vdf" ] && break
done

sed -n 's/^[[:space:]]*"path"[[:space:]]*"\(.*\)"[[:space:]]*$/\1/p' "$steam/steamapps/libraryfolders.vdf" 2>/dev/null |
while IFS= read -r library; do
    for manifest in "$library"/steamapps/appmanifest_*.acf; do
        [ -f "$manifest" ] || continue

        awk '
            function value(line) {
                sub(/^\t"[^"]*"[ \t]*"/, "", line)
                sub(/"[ \t\r]*$/, "", line)
                gsub(/\\"/, "\"", line)
                return line
            }
            /^\t"appid"/ { id = value($0) }
            /^\t"name"/ { name = value($0) }
            /^\t"StateFlags"/ { flags = value($0) }
            END {
                # The 4 bit means fully installed. Anything still downloading can wait.
                if (id && int(flags / 4) % 2 && name !~ /^(Proton( |$)|Steam Linux Runtime|Steamworks )/)
                    print id "\t" name
            }
        ' "$manifest"
    done
done

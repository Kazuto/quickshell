.pragma library

.import "AppGlyphs.js" as AppGlyphs

// Shared app-name → icon-glyph mapping. Used by WindowTitle.qml (active
// window) and Tray.qml (system tray) so both places render the same
// monochrome glyph for a given app instead of maintaining two separate
// icon maps.
//
// Lookup keys are matched as case-insensitive substrings against a
// normalized (lowercased, non-alphanumerics stripped) version of whatever
// identifier is available — a Hyprland window class, a tray item id, a
// desktop entry id, etc. — so "1Password_status_icon_1", "1password", and
// "one_password" all resolve to the same entry.
//
// Two icon sources are supported:
//   - sketchybar-app-font glyphs (colorful per-app icon font, PUA codepoints)
//   - a Nerd Font fallback (font: null) for apps with no sketchybar glyph,
//     using the same codepoints as Icon.qml's singleton properties so the
//     look stays consistent with the rest of the bar.

function normalize(id) {
    return String(id || "").toLowerCase().replace(/[^a-z0-9]/g, "")
}

// Ordered so more specific keys can be listed before broader ones if ever
// needed; lookup just takes the first substring match.
var ENTRIES = [
    { match: ["ghostty"],               glyph: "ghostty" },
    { match: ["firefox"],               glyph: "firefox" },
    { match: ["googlechrome", "chrome"], glyph: "googlechrome" },
    { match: ["bruno"],                 glyph: "bruno" },
    { match: ["slack"],                 glyph: "slack" },
    { match: ["vesktop"],               glyph: "vesktop" },
    { match: ["discord"],               glyph: "discord" },
    { match: ["spotify"],               glyph: "spotify" },
    { match: ["dolphin"],               glyph: "dolphin" },
    { match: ["kitty"],                 glyph: "kitty" },
    { match: ["obsidian"],              glyph: "obsidian" },
    { match: ["code"],                  glyph: "code" },
    { match: ["thunderbird"],           glyph: "thunderbird" },
    { match: ["vivaldi"],               glyph: "vivaldi" },
    { match: ["docker"],                glyph: "docker" },
    { match: ["protonmail"],            glyph: "protonmail" },
    { match: ["tableplus"],             glyph: "tableplus" },
    { match: ["steam"],                 glyph: "steam" },
    { match: ["figma"],                 glyph: "figma" },
    { match: ["onepassword", "1password"], glyph: "onepassword" },
]

// Display-name rewrites for apps whose window class / tray id isn't
// human-readable as-is (e.g. "org.kde.dolphin" -> "Dolphin").
var LABELS = [
    { match: ["ghostty"],                 label: "Ghostty" },
    { match: ["firefox"],                 label: "Firefox" },
    { match: ["googlechrome", "chrome"],  label: "Chrome" },
    { match: ["bruno"],                   label: "Bruno" },
    { match: ["slack"],                   label: "Slack" },
    { match: ["vesktop", "discord"],      label: "Discord" },
    { match: ["spotify"],                 label: "Spotify" },
    { match: ["dolphin"],                 label: "Dolphin" },
    { match: ["thunar"],                  label: "Thunar" },
    { match: ["kitty"],                   label: "Kitty" },
    { match: ["obsidian"],                label: "Obsidian" },
    { match: ["code"],                    label: "VS Code" },
    { match: ["thunderbird"],             label: "Thunderbird" },
    { match: ["vivaldi"],                 label: "Vivaldi" },
    { match: ["docker"],                  label: "Docker" },
    { match: ["protonmail"],              label: "Proton Mail" },
    { match: ["tableplus"],               label: "TablePlus" },
    { match: ["figma"],                   label: "Figma" },
    { match: ["onepassword", "1password"], label: "1Password" },
]

function findEntry(id, table) {
    var norm = normalize(id)
    if (!norm) return null
    for (var i = 0; i < table.length; i++) {
        var entry = table[i]
        for (var j = 0; j < entry.match.length; j++) {
            if (norm.indexOf(entry.match[j]) >= 0) return entry
        }
    }
    return null
}

// A glyph of the font by its normalized name, so nothing here depends on the
// codepoints of one build of it. Returns { char, font } or null.
function glyphNamed(name) {
    if (!AppGlyphs.GLYPHS.hasOwnProperty(name)) return null
    return { char: AppGlyphs.GLYPHS[name], font: "sketchybar-app-font" }
}

// Returns { char, font } or null if there's no known glyph for this id.
// `font` is either "sketchybar-app-font" or null (meaning: use the caller's
// regular Nerd Font family).
function glyphFor(id) {
    var entry = findEntry(id, ENTRIES)
    return entry ? glyphOf(entry) : null
}

function glyphOf(entry) {
    return entry.glyph ? glyphNamed(entry.glyph) : { char: entry.char, font: entry.font }
}

// Returns { char, font } or null for an app in the launcher, going by its name, icon,
// window class and desktop id. These have to match exactly, because a substring would
// find far too much across the whole font. The names in ENTRIES count too, for apps the
// font calls something else, like "1password".
function glyphForApp(app) {
    var ids = [app.name, app.icon, app.startupClass, app.id, String(app.id || "").split(".").pop()]
    for (var i = 0; i < ids.length; i++) {
        var key = normalize(ids[i])
        var glyph = glyphNamed(key)
        if (glyph) return glyph

        for (var j = 0; j < ENTRIES.length; j++) {
            if (ENTRIES[j].match.indexOf(key) >= 0) return glyphOf(ENTRIES[j])
        }
    }
    return null
}

// Returns a human-readable app name for this id, falling back to the
// original id string (trimmed of common tray-id suffixes) if unknown.
function labelFor(id) {
    var entry = findEntry(id, LABELS)
    if (entry) return entry.label

    var raw = String(id || "").trim()
    if (!raw) return ""
    // Strip common StatusNotifierItem id suffixes like "_status_icon_1"
    return raw.replace(/[-_]?status[-_]?icon[-_]?\d*$/i, "")
        .replace(/[-_]?client$/i, "")
        .trim()
}

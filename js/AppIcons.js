.pragma library

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
// `offsetX` is an optional manual horizontal nudge (in px) for glyphs whose
// font has an asymmetric left/right side-bearing baked in — generic
// centering (anchors.centerIn / AlignHCenter) centers the glyph's *declared*
// bounding box, which doesn't always match where the visible ink actually
// sits, so some glyphs need a small manual correction to look centered.
var ENTRIES = [
    { match: ["ghostty"],               char: "\uEAD9", font: "sketchybar-app-font" },
    { match: ["firefox"],               char: "\uEABF", font: "sketchybar-app-font" },
    { match: ["googlechrome", "chrome"], char: "\uEAE3", font: "sketchybar-app-font" },
    { match: ["bruno"],                 char: "\uEA4D", font: "sketchybar-app-font" },
    { match: ["slack"],                 char: "\uEC04", font: "sketchybar-app-font" },
    { match: ["vesktop"],               char: "\uEC51", font: "sketchybar-app-font" },
    { match: ["discord"],               char: "\uEA9C", font: "sketchybar-app-font" },
    { match: ["spotify"],               char: "\uEC0F", font: "sketchybar-app-font", offsetX: 3 },
    { match: ["dolphin"],               char: "\uEAA0", font: "sketchybar-app-font" },
    { match: ["kitty"],                 char: "\uEB22", font: "sketchybar-app-font" },
    { match: ["obsidian"],              char: "\uEB81", font: "sketchybar-app-font" },
    { match: ["code"],                  char: "\uEA72", font: "sketchybar-app-font" },
    { match: ["thunderbird"],           char: "\uEC34", font: "sketchybar-app-font" },
    { match: ["vivaldi"],               char: "\uEC56", font: "sketchybar-app-font" },
    { match: ["docker"],                char: "\uEA9E", font: "sketchybar-app-font" },
    { match: ["protonmail"],            char: "\uEBC3", font: "sketchybar-app-font" },
    { match: ["tableplus"],             char: "\uEC25", font: "sketchybar-app-font" },
    // No sketchybar-app-font glyph for 1Password — fall back to the Nerd
    // Font lock icon (same codepoint as Icon.qml's `lock` property).
    { match: ["onepassword", "1password"], char: "\uF023", font: null },
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

// Returns { char, font, offsetX } or null if there's no known glyph for
// this id. `font` is either "sketchybar-app-font" or null (meaning: use
// the caller's regular Nerd Font family). `offsetX` defaults to 0.
function glyphFor(id) {
    var entry = findEntry(id, ENTRIES)
    if (!entry) return null
    return { char: entry.char, font: entry.font, offsetX: entry.offsetX || 0 }
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

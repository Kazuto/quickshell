.pragma library

// Turns hyprland.conf bind lines into the labelled sections of the hotkey
// sheet. Pure string handling, so it can be exercised without a running shell.

var overlayLabels = {
    "launcher-toggle": "Launcher",
    "quick-toggle": "Quick access",
    "emoji-toggle": "Emoji",
    "wallpaper-toggle": "Wallpaper",
    "hotkeys-toggle": "This sheet",
    "power-toggle": "System",
    "menu-toggle": "Menu"
}

var keyNames = {
    PERIOD: ".",
    COMMA: ",",
    SLASH: "/",
    RETURN: "Return",
    ESCAPE: "Esc",
    SPACE: "Space",
    TAB: "Tab"
}

var modNames = { SUPER: "Super", SHIFT: "Shift", ALT: "Alt", CTRL: "Ctrl", CONTROL: "Ctrl" }

function chord(mods, key) {
    var parts = mods.map(function(m) { return modNames[m] || m })
    var upper = key.toUpperCase()
    parts.push(keyNames[upper] || (key.length === 1 ? upper : key))
    return parts.join(" ")
}

function parseLine(line) {
    var match = line.match(/^\s*bind[a-z]*\s*=\s*([^,]*),\s*([^,]+?)\s*,\s*([^,#\s]+)\s*,?\s*(.*)$/)
    if (!match) return null
    if (/^\s*bindm/.test(line)) return null
    var key = match[2].trim()
    // Media keys and mouse wheel binds aren't worth a row on the sheet
    if (/^XF86/.test(key) || /^mouse/.test(key)) return null
    var args = match[4]
    var comment = ""
    var hash = args.indexOf(" # ")
    if (hash >= 0) {
        comment = args.substring(hash + 3).trim()
        args = args.substring(0, hash)
    }
    return {
        mods: match[1].trim().split(/\s+/).filter(function(m) { return m.length > 0 }),
        key: key,
        dispatcher: match[3].trim(),
        args: args.trim(),
        comment: comment
    }
}

function directionKeys(keys) {
    return keys.join(" ")
}

function digitRange(keys) {
    var digits = keys.slice().sort()
    return digits[0] + "-" + digits[digits.length - 1]
}

function capitalize(word) {
    return word.charAt(0).toUpperCase() + word.slice(1)
}

function execRow(bind) {
    var socket = bind.args.match(/echo\s+"([a-z-]+)"\s*\|\s*socat/)
    if (socket) return { section: "overlays", label: overlayLabels[socket[1]] || socket[1], command: socket[1] }

    var shot = bind.args.match(/grimblast\b.*?\b(save|copy)\s+(\w+)/)
    if (shot) {
        var frozen = bind.args.indexOf("--freeze") >= 0 ? ", frozen" : ""
        return { section: "capture", label: capitalize(shot[1]) + " " + shot[2] + frozen }
    }

    if (bind.comment) return { section: "tools", label: bind.comment }
    if (bind.args.indexOf("smart-fullscreen") >= 0) return { section: "windows", label: "Fullscreen" }
    if (bind.args.indexOf("hyprpicker") >= 0) return { section: "tools", label: "Color picker" }
    if (bind.args.indexOf("set-wallpaper") >= 0) return { section: "tools", label: "Random wallpaper" }

    // "ghostty -e yazi" reads better as yazi than as the terminal hosting it
    var words = bind.args.split(/\s+/)
    var dashE = words.indexOf("-e")
    var program = dashE >= 0 && words[dashE + 1] ? words[dashE + 1] : words[0]
    return { section: "tools", label: capitalize(program.split("/").pop()) }
}

function parse(text) {
    var rows = { overlays: [], workspaces: [], windows: [], capture: [], tools: [] }
    var overlayKeys = {}
    var grouped = {}

    function addGrouped(id, section, label, bind) {
        var groupId = id + "|" + bind.mods.join(" ")
        if (!grouped[groupId]) {
            grouped[groupId] = { section: section, label: label, mods: bind.mods, keys: [] }
            rows[section].push(grouped[groupId])
        }
        grouped[groupId].keys.push(bind.key)
    }

    var plainWindowActions = {
        killactive: "Close",
        togglefloating: "Float",
        fullscreen: "Fullscreen",
        togglegroup: "Group",
        changegroupactive: "Next in group"
    }

    var lines = text.split("\n")
    for (var i = 0; i < lines.length; i++) {
        var bind = parseLine(lines[i])
        if (!bind) continue

        if (bind.dispatcher === "exec") {
            var row = execRow(bind)
            var keys = chord(bind.mods, bind.key)
            if (row.command) overlayKeys[row.command] = keys
            rows[row.section].push({ label: row.label, keys: keys })
        } else if (plainWindowActions[bind.dispatcher]) {
            rows.windows.push({ label: plainWindowActions[bind.dispatcher], keys: chord(bind.mods, bind.key) })
        } else if (bind.dispatcher === "movefocus") {
            addGrouped("focus", "windows", "Focus", bind)
        } else if (bind.dispatcher === "movewindow") {
            addGrouped("move", "windows", "Move", bind)
        } else if (bind.dispatcher === "resizeactive") {
            addGrouped("resize", "windows", "Resize", bind)
        } else if (bind.dispatcher === "workspace") {
            addGrouped("goto", "workspaces", "Go to", bind)
        } else if (bind.dispatcher === "movetoworkspace" || bind.dispatcher === "movetoworkspacesilent") {
            addGrouped("send", "workspaces", "Send window", bind)
        } else if (bind.dispatcher === "togglespecialworkspace") {
            rows.workspaces.push({ label: "Scratchpad", keys: chord(bind.mods, bind.key) })
        }
    }

    function finish(list) {
        return list.map(function(row) {
            if (!row.mods) return row
            var isDigits = row.keys.every(function(k) { return /^\d$/.test(k) })
            var tail = isDigits ? digitRange(row.keys) : directionKeys(row.keys)
            var mods = row.mods.map(function(m) { return modNames[m] || m })
            return { label: row.label, keys: mods.concat([tail]).join(" ") }
        })
    }

    var titles = [
        ["overlays", "Overlays"],
        ["workspaces", "Workspaces"],
        ["tools", "Tools"],
        ["windows", "Windows"],
        ["capture", "Capture"]
    ]
    var sections = []
    for (var t = 0; t < titles.length; t++) {
        var finished = finish(rows[titles[t][0]])
        if (finished.length > 0) sections.push({ title: titles[t][1], rows: finished })
    }
    return { sections: sections, overlayKeys: overlayKeys }
}

.pragma library

// Shared key-classification helpers for search-style overlays
// (LauncherOverlay, EmojiPickerOverlay). Each function takes a QML
// KeyEvent and returns whether it matches a given navigation/action intent,
// so overlays don't have to repeat the same verbose modifier checks.

function isEscape(event) {
    return event.key === Qt.Key_Escape
}

function isConfirm(event) {
    return event.key === Qt.Key_Return || event.key === Qt.Key_Enter
}

function isBackspace(event) {
    return event.key === Qt.Key_Backspace
}

// Up arrow, or Ctrl+K (vim-style)
function isPrev(event) {
    return event.key === Qt.Key_Up
        || (event.key === Qt.Key_K && (event.modifiers & Qt.ControlModifier))
}

// Down arrow, or Ctrl+J (vim-style)
function isNext(event) {
    return event.key === Qt.Key_Down
        || (event.key === Qt.Key_J && (event.modifiers & Qt.ControlModifier))
}

// Left arrow, or Ctrl+H (vim-style) — used by grid-based overlays
function isPrevColumn(event) {
    return event.key === Qt.Key_Left
        || (event.key === Qt.Key_H && (event.modifiers & Qt.ControlModifier))
}

// Right arrow, or Ctrl+L (vim-style) — used by grid-based overlays
function isNextColumn(event) {
    return event.key === Qt.Key_Right
        || (event.key === Qt.Key_L && (event.modifiers & Qt.ControlModifier))
}

// A plain printable character with no/shift-only modifiers — i.e. text
// that should be appended to a search filter rather than treated as a
// keybinding.
function isPrintableChar(event) {
    return !!event.text
        && event.text.length === 1
        && event.text.charCodeAt(0) >= 32
        && event.text.charCodeAt(0) !== 127
        && (event.modifiers === Qt.NoModifier || event.modifiers === Qt.ShiftModifier)
}

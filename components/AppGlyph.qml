import QtQuick

// An icon from js/AppIcons.js. Its font's glyphs sit at the left of a much wider advance, so
// this centers what's actually drawn in the parent rather than the character's box.
Text {
    id: root

    x: Math.round((parent.width - metrics.tightBoundingRect.width) / 2 - metrics.tightBoundingRect.x)
    y: Math.round((parent.height - metrics.tightBoundingRect.height) / 2 - metrics.tightBoundingRect.y - baselineOffset)

    TextMetrics {
        id: metrics
        font: root.font
        text: root.text
    }
}

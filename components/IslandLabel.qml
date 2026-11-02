import QtQuick
import "root:/"

// Text in the Island v1 type scale. JetBrains Mono is tabular throughout, so
// clocks and timers never jitter.
Text {
    property string kind: "body"  // display | title | island | body | meta

    font.family: Config.moduleFontFamily
    font.pixelSize: kind === "display" ? 48 : kind === "title" ? 16 : kind === "meta" ? 11 : 12
    font.weight: kind === "body" || kind === "meta" ? Font.Normal : Font.DemiBold
    color: kind === "meta" ? Theme.textDim : Theme.text
    textFormat: Text.PlainText
    maximumLineCount: 1
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
}

import QtQuick
import "root:/"

// A small captioned value on a card
Rectangle {
    id: stat

    property string label: ""
    property string value: ""
    property color valueColor: Theme.text
    property string valueKind: "body"

    implicitHeight: column.implicitHeight + 20
    radius: Config.cardRadius
    color: Theme.surfaceLow

    Column {
        id: column
        x: 14
        y: 10
        width: parent.width - 28
        spacing: 2

        IslandLabel {
            text: stat.label
            kind: "meta"
        }

        IslandLabel {
            width: parent.width
            text: stat.value
            kind: stat.valueKind
            color: stat.valueColor
        }
    }
}

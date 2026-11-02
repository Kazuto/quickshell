import QtQuick
import "root:/"

// Label and value rows on a card, with an optional line above them
Rectangle {
    id: card

    property var rows: []  // [{ label, value, color? }]
    property int labelWidth: 96
    default property alias lead: topSlot.data

    implicitHeight: column.implicitHeight + 24
    radius: Config.cardRadius
    color: Theme.surfaceLow

    Column {
        id: column
        x: 14
        y: 12
        width: parent.width - 28
        spacing: 5

        Column {
            id: topSlot
            width: parent.width
        }

        Repeater {
            model: card.rows

            delegate: Row {
                required property var modelData

                width: column.width
                height: 16

                IslandLabel {
                    width: card.labelWidth
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.label
                    kind: "meta"
                }

                IslandLabel {
                    width: parent.width - card.labelWidth
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.value
                    color: modelData.color || Theme.text
                    font.pixelSize: 11
                }
            }
        }
    }
}

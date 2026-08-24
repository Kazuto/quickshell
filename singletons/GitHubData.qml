pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    property int notificationCount: 0
    property var notifications: []

    function refresh() {
        notificationProcess.running = false
        notificationProcess.running = true
    }

    // Fetch notifications using GitHub CLI
    Process {
        id: notificationProcess
        running: true
        command: ["sh", "-c", "gh api notifications --jq '.[] | {id: .id, title: .subject.title, type: .subject.type, repo: .repository.full_name, unread: .unread, updated_at: .updated_at, url: (.subject.url | sub(\"api.github.com/repos/\"; \"github.com/\") | sub(\"/pulls/\"; \"/pull/\"))}' 2>/dev/null | jq -s -c '.'"]

        stdout: SplitParser {
            onRead: data => {
                var trimmed = data.trim()
                if (trimmed.length === 0) return

                try {
                    var parsed = JSON.parse(trimmed)
                    notifications = parsed
                    notificationCount = parsed.filter(n => n.unread).length
                } catch (e) {
                    // Ignore parse errors for empty or partial output
                }
            }
        }
    }

    Timer {
        interval: 300000  // Update every 5 minutes
        running: true
        repeat: true
        onTriggered: refresh()
    }
}

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var notifications: []

    function refresh() {
        notificationProcess.running = false
        notificationProcess.running = true
    }

    // "PullRequest" -> "pull request"
    function typeLabel(type) {
        return String(type || "").replace(/([a-z])([A-Z])/g, "$1 $2").toLowerCase()
    }

    function typeIcon(type) {
        if (type === "PullRequest") return "git-pull-request"
        if (type === "Issue") return "issue"
        return "github"
    }

    // Threads without a page of their own, such as CI runs, open the repository
    Process {
        id: notificationProcess
        running: true
        command: ["sh", "-c", "gh api notifications --jq '.[] | {id: .id, title: .subject.title, type: .subject.type, repo: .repository.full_name, unread: .unread, updated_at: .updated_at, url: ((.subject.url // .repository.url) | sub(\"api.github.com/repos/\"; \"github.com/\") | sub(\"/pulls/\"; \"/pull/\"))}' 2>/dev/null | jq -s -c '.'"]

        stdout: SplitParser {
            onRead: data => {
                var trimmed = data.trim()
                if (trimmed.length === 0) return

                try {
                    // An error response has no threads in it, such as when logged out
                    var threads = JSON.parse(trimmed)
                    root.notifications = Array.isArray(threads) ? threads.filter(t => t.id) : []
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

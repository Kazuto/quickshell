pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Caffeine mode: prevents the system from going idle (screen lock, dpms
// off, suspend) while enabled.
//
// hypridle natively implements the org.freedesktop.ScreenSaver DBus
// interface (the same one Firefox/Steam/mpv use to block idle during
// playback), so we register a proper inhibitor via Inhibit()/UnInhibit()
// instead of signalling the process. This keeps hypridle fully running
// (lock_cmd, before_sleep_cmd, resume hooks, etc. still work normally) -
// only its timeout listeners (lock, dpms, suspend) are suppressed while
// inhibited.
//
// NOTE: deliberately not using a long-lived `systemd-inhibit ... sleep
// infinity` helper process here. Quickshell config reloads can outlive
// (or fail to clean up) such background processes, leaving an orphaned
// lock behind even after this module reports itself as "off". The
// DBus cookie is request/response based and has no such lifecycle risk.
//
// `active`/`cookie` live in PersistentProperties rather than plain
// properties: the DBus inhibitor is held by hypridle regardless of what
// quickshell's QML tree is doing, so if a config reload reset our state
// back to defaults, the module would show "off" while hypridle is still
// inhibited forever (and toggling "on" again would leak a second,
// unreleasable cookie). Persisting the state keeps the UI in sync with
// reality across reloads.
Singleton {
    id: root

    property alias active: persist.active
    property alias cookie: persist.cookie

    PersistentProperties {
        id: persist
        reloadableId: "caffeineData"

        property bool active: false
        property int cookie: -1
    }

    function toggle() {
        setActive(!active)
    }

    function setActive(value) {
        if (active === value) return

        if (value) {
            inhibitProcess.running = true
        } else if (cookie >= 0) {
            uninhibitProcess.command = ["gdbus", "call", "--session",
                "--dest", "org.freedesktop.ScreenSaver",
                "--object-path", "/org/freedesktop/ScreenSaver",
                "--method", "org.freedesktop.ScreenSaver.UnInhibit",
                String(cookie)]
            uninhibitProcess.running = true
            cookie = -1
        }

        active = value
    }

    // Registers an inhibitor. hypridle replies with the cookie needed to
    // release it again.
    Process {
        id: inhibitProcess
        command: ["gdbus", "call", "--session",
            "--dest", "org.freedesktop.ScreenSaver",
            "--object-path", "/org/freedesktop/ScreenSaver",
            "--method", "org.freedesktop.ScreenSaver.Inhibit",
            "quickshell", "Caffeine mode enabled"]

        stdout: StdioCollector {
            onStreamFinished: {
                // Output looks like: (uint32 1526,)
                const match = this.text.match(/(\d+)/)
                if (match) root.cookie = parseInt(match[1], 10)
            }
        }
    }

    Process {
        id: uninhibitProcess
    }

    Component.onDestruction: {
        if (active) setActive(false)
    }
}

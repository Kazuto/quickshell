# QuickShell Configuration

Qt/QML-based widget toolkit for creating custom overlays on Hyprland using proper IPC.

## Structure

- `shell.qml` - Main entry point with IPC socket server
- `Overlay.qml` - Example overlay widget (centered panel with controls)
- `SpotifyOverlay.qml` - Spotify player overlay with album art and controls
- `~/.local/bin/quickshell-toggle-overlay` - IPC toggle script

## Usage

### Overlays

#### Example Overlay
- Press **SUPER + O** to toggle
- Or run: `echo "overlay-toggle" | socat - UNIX-CONNECT:/tmp/quickshell.sock`

#### Spotify Overlay
- **Click the Spotify module in Waybar** to toggle
- Shows: Album art, track info, playback controls, progress bar
- Middle-click Waybar module: Play/Pause
- Scroll on Waybar module: Next/Previous track
- Or run: `echo "spotify-toggle" | socat - UNIX-CONNECT:/tmp/quickshell.sock`

### IPC Commands
Send commands via Unix socket at `/tmp/quickshell.sock`:

**Example Overlay:**
- `overlay-toggle` - Toggle overlay visibility
- `overlay-show` - Show overlay
- `overlay-hide` - Hide overlay

**Spotify Overlay:**
- `spotify-toggle` - Toggle Spotify overlay
- `spotify-show` - Show Spotify overlay
- `spotify-hide` - Hide Spotify overlay

### Customization

The overlay is built with QML (Qt Markup Language), which is similar to JavaScript/React.

#### Modify the overlay:
Edit `Overlay.qml` to customize:
- **Size**: Change `width` and `height` in the container Rectangle
- **Colors**: Modify `color` property (supports hex with alpha: `#AARRGGBB`)
- **Layout**: Add/remove components in the ColumnLayout
- **Actions**: Update `onClicked` handlers to run actual commands

#### Example: Run a command on button click
```qml
RoundButton {
    text: "🔒"
    onClicked: {
        // Run a shell command
        Qt.callLater(() => {
            var process = Qt.createQmlObject('import QtQuick 2.0; import Qt.labs.process 1.0; Process {}', parent);
            process.start("swaylock");
        })
    }
}
```

#### Add more overlays:
Create new `.qml` files and import them in `shell.qml`:

```qml
ShellRoot {
    Overlay {}
    StatusWidget {}  // Your new widget
    MusicPlayer {}   // Another widget
}
```

## Blur Effect

For the frosted glass effect to work, ensure Hyprland blur is enabled:
```conf
decoration {
    blur {
        enabled = true
        size = 3
        passes = 3
    }
}
```

## Resources

- [QuickShell Documentation](https://outfoxxed.me/quickshell/)
- [QML Documentation](https://doc.qt.io/qt-6/qmlapplications.html)
- [Qt Quick Controls](https://doc.qt.io/qt-6/qtquickcontrols-index.html)

## Troubleshooting

### Overlay not showing
1. Check if QuickShell is running: `pgrep quickshell`
2. View logs: `journalctl --user -u quickshell -f` (if running as service)
3. Test manually: `quickshell` in terminal

### Keybind not working
- Reload Hyprland: **SUPER + R**
- Check keybind: `hyprctl binds | grep quickshell`

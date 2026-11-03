# QuickShell Configuration

The Island v1 desktop shell for Hyprland: one pill at the top center of every
output, with everything else morphing out of it.

## Structure

- `windows/Island.qml` - the per-output window; picks what the outline shows
- `windows/IslandScrim.qml` - click catcher and dim behind open panels
- `components/IslandSurface.qml` - the outline and its motion
- `modules/` - what the pill shows at rest: idle, media, transients, bubbles
- `panels/` - everything that grows out of it, opened through `AppState.openPanel`
- `overlays/` - what still opens as its own window: tray menus and Ollama
- `singletons/IslandData.qml` - who gets the core, by the design's priority order
- `Theme.qml`, `Config.qml` - the design tokens

## Accent

`scripts/apply-accent.sh` takes the accent from the wallpaper and passes it on to
Hyprland's borders, Ghostty's cursor, Neovim, Yazi, tmux and the Starship directory.
Backgrounds and syntax colors stay Catppuccin Mocha. It runs from `set-wallpaper.sh`,
and "Derive accent from wallpaper" in the wallpaper picker turns it off. Generated
files go in `~/.cache/quickshell`. Yazi uses palette color 89, which the script
redefines in Ghostty, so open Yazi windows recolor without a restart.

GTK apps need the `catppuccin-mocha-pink-standard+default` theme installed. The script
makes two accent copies of it in `~/.local/share/themes` and switches between them,
which recolors Thunar and Chrome's "Use GTK" mode live. libadwaita apps read
`~/.config/gtk-4.0/gtk.css` at launch. Vivaldi can load `~/.cache/quickshell/vivaldi`
as a CSS mod, also at launch: turn on CSS modifications in `vivaldi://experiments` and
set the folder under Custom UI Modifications.

## Area selector

Area screenshots and recordings pick their area with yarn from the screen's corners to the
pointer. Drag to select, click for the window under the pointer or the whole screen, Esc or
right click to cancel. `area-select` on the socket answers with `x,y wxh`, and
`scripts/area-select/slurp` stands in for slurp so grimblast can use it: the keybinds put
that folder first in PATH. The look is in `shaders/yarn.*`, and the compile command for the
`.qsb` files is at the top of each shader.

## IPC

Send commands to the socket at `/tmp/quickshell.sock`, for example
`echo "launcher-toggle" | socat - UNIX-CONNECT:/tmp/quickshell.sock`.

- Panels: `launcher-toggle`, `quick-toggle`, `emoji-toggle`, `hotkeys-toggle`,
  `wallpaper-toggle`, `clipboard-toggle`, `media-toggle`, `notifications-toggle`,
  `calendar-toggle`, `timer-toggle`, `recorder-toggle`, `control-toggle`,
  `system-toggle` (also `menu-toggle`, `power-toggle`), `network-toggle`,
  `bluetooth-toggle`, `audio-toggle`, `vpn-toggle`, `devices-toggle`,
  `battery-toggle`, `monitor-toggle`
- OSD: `osd-volume:<0-100>:<muted|unmuted>`, `osd-brightness:<0-100>`

## Developing

Quickshell hot-reloads the config it runs, so editing the deployed files changes
the live shell. To work on a checkout beside it instead:

```sh
QS_DEV=1 quickshell -p path/to/quickshell
```

`QS_DEV=1` uses `/tmp/quickshell-dev.sock` and reserves no screen space. Run it
under `dbus-run-session` to also test the notification server, which otherwise
stays with the live shell.

## Dependencies

`cliphist`, `wf-recorder`, `slurp`, `grimblast`, `hyprpicker`, `awww`, `magick`,
`brightnessctl`, `powerprofilesctl`, `pamixer` and `playerctl`-style MPRIS players
for the rest.

## Troubleshooting

- Overlay not showing: check `pgrep quickshell`, or run `quickshell` in a terminal
- Keybind not working: reload with **SUPER + R**, check `hyprctl binds | grep quickshell`

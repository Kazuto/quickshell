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
Hyprland's borders, Ghostty's cursor, Neovim, Yazi, tmux, herdr, lazygit, lazydocker
and the Starship directory. Backgrounds and syntax colors stay Catppuccin Mocha. It runs
from `set-wallpaper.sh`, and "Derive accent from wallpaper" in the wallpaper picker turns
it off. Generated files go in `~/.cache/quickshell`. Yazi uses palette color 89, which the
script redefines in Ghostty, so open Yazi windows recolor without a restart. herdr can't
include another file, so the script sets `accent` under `[theme.custom]` in herdr's own
`config.toml` and reloads the running server.

lazygit reads `~/.cache/quickshell/accent-lazygit.yml` on top of its own config when the
shell exports `LG_CONFIG_FILE` with both files, as the dotfiles' zsh `.init` does.
lazydocker can't layer config files, so the script writes the theme to
`~/.config/lazydocker/config.yml`, but only while that file is empty or was written by
the script, and lazydocker reads it at launch. Both keep the selected line Mocha
gray, since the light accent would hide the text on it.

GTK apps need the `catppuccin-mocha-pink-standard+default` theme installed. The script
makes two accent copies of it in `~/.local/share/themes` and switches between them,
which recolors Thunar and Chrome's "Use GTK" mode live. libadwaita apps read
`~/.config/gtk-4.0/gtk.css` at launch. Vivaldi can load `~/.cache/quickshell/vivaldi`
as a CSS mod, also at launch: turn on CSS modifications in `vivaldi://experiments` and
set the folder under Custom UI Modifications.

## Area selector

Area screenshots and recordings pick their area with yarn from the screen's corners to the
pointer. Drag to select, hold Space while dragging to move the area, click for the window
under the pointer or the whole screen, Esc or right click to cancel. `area-select` on the socket answers with `x,y wxh`, and
`scripts/area-select/slurp` stands in for slurp so grimblast can use it: the keybinds put
that folder first in PATH. The look is in `shaders/yarn.*`, and the compile command for the
`.qsb` files is at the top of each shader.

## Updates

An icon appears on the island when something can be updated, a restart is pending, or
something about the sources looks wrong. `scripts/check-updates.sh` asks apt, pacman and an
AUR helper, snap, flatpak and fwupd, whichever are installed, every hour and whenever the
panel opens. It needs no root. Installing runs `scripts/run-updates.sh` in a terminal, so
each manager can show what it's about to do. Packages go together and firmware one device at
a time. Tools built by hand aren't covered.

## Steam games

The launcher also lists the installed Steam games. `scripts/steam-games.sh` reads them from
Steam's library manifests whenever the launcher opens, leaving out Proton and the runtimes.
A game with a desktop shortcut from Steam isn't listed twice. They start through the `steam`
command, so games from elsewhere still need a `.desktop` file.

## Webcam tracking

With an EMEET PIXY plugged in, the control center gets a Tracking tile that switches the
camera's AI tracking. `scripts/pixy-track` sends the command over the camera's vendor HID
interface, using the protocol from [omarchy-emeet-pixy](https://github.com/nille/omarchy-emeet-pixy).
It also works on its own: `pixy-track [toggle|on|off|status]`. The camera only reports its mode
while an app is using it, so when it's idle the tile shows the last known state as "camera idle".
The hidraw node is root-only, so it needs a udev rule once:

```sh
echo 'SUBSYSTEM=="hidraw", ATTRS{idVendor}=="328f", ATTRS{idProduct}=="00c0", TAG+="uaccess"' \
  | sudo tee /etc/udev/rules.d/70-emeet-pixy.rules
sudo udevadm control --reload && sudo udevadm trigger --subsystem-match=hidraw
```

## App icons

The tray and launcher draw app icons from `js/sketchybar-app-font.ttf`, which `Main.qml`
loads so that an installed copy doesn't matter. Each build of the font moves its codepoints,
so replacing the file means regenerating `js/AppGlyphs.js`, as `js/README.md` shows.
`js/AppIcons.js` picks glyphs by name, so it doesn't change. The launcher shows the app's first
letter when the font has no icon with its exact name.

## Hyprland versions

Both config formats work. Hyprland 0.57 only reads `hyprland.lua`, older releases only
`hyprland.conf`, and `hyprctl` takes different commands with each.
`singletons/HyprlandData.qml` asks the running Hyprland which one it's using and sends the
right form. The hotkey sheet reads that same file, so with Lua each bind has to stay on one
line with its command inline. It also checks the version, because 0.57 changed how exclusive
layers get the keyboard and the pointer, and the scrim behind panels depends on that.

## IPC

Send commands to the socket at `/tmp/quickshell.sock`, for example
`echo "launcher-toggle" | socat - UNIX-CONNECT:/tmp/quickshell.sock`.

- Panels: `launcher-toggle`, `quick-toggle`, `emoji-toggle`, `hotkeys-toggle`,
  `wallpaper-toggle`, `clipboard-toggle`, `media-toggle`, `notifications-toggle`,
  `calendar-toggle`, `timer-toggle`, `recorder-toggle`, `control-toggle`,
  `system-toggle` (also `menu-toggle`, `power-toggle`), `network-toggle`,
  `bluetooth-toggle`, `audio-toggle`, `vpn-toggle`, `devices-toggle`,
  `battery-toggle`, `monitor-toggle`, `updates-toggle`
- Media: `media-play-pause`, `media-next`, `media-previous`, for the player the island shows
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
for the rest. `jq` for firmware updates and, on Arch, `pacman-contrib` for up-to-date
package counts.

## Troubleshooting

- Overlay not showing: check `pgrep quickshell`, or run `quickshell` in a terminal
- Keybind not working: reload with **SUPER + R**, check `hyprctl binds | grep quickshell`

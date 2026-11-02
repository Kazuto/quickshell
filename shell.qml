// Grayscale text: the outputs mix landscape and rotated panels, so subpixel
// antialiasing would color-fringe on most of them.
//@ pragma Env QSG_DISTANCEFIELD_ANTIALIASING=gray

import QtQuick
import Quickshell

import "root:/"

ShellRoot {
    id: root

    Main {}
}

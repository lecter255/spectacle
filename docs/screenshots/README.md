# Lens images

Images of Lens, a keyboard-first window manager for macOS based on [Spectacle](https://github.com/eczarny/spectacle) by Eric Czarny. Use them for a portfolio, a README or a release page.

**These are design mockups and the app icon, not screenshots of the running app.** The mockups were drawn while choosing the new interface (November 2026) and rendered to PNG at 2x. The shipping SwiftUI interface follows directions B and C below but may differ in detail. Some mockups show "Tiler", a placeholder name used before the app was named Lens.

All mockups are 2x PNGs; sizes below are in points (pixels are double).

## App icon

| File | What it shows |
|---|---|
| [icon/lens-app-icon-1024.png](icon/lens-app-icon-1024.png) | The Lens app icon as it ships in the app (1024×1024): a single lens with its left half tinted, a nod to Spectacle without copying its icon. |
| [icon/lens-app-icon-dark-1024.png](icon/lens-app-icon-dark-1024.png) | The dark-appearance variant of the same icon, from the design exploration. |

## Chosen interface direction (mockups)

Lens uses direction **B, the layout map** (edit shortcuts on a picture of the screen) together with the **snap HUD** from direction C.

| File | Size | What it shows |
|---|---|---|
| [mockups/chosen/layout-map-editor.png](mockups/chosen/layout-map-editor.png) | 880×580 | Settings window: every window position as a card with its shortcut, and a side panel for editing the selected one, including which sizes a repeated press cycles through (½ → ⅔ → ¾ → ¼ → ⅓). |
| [mockups/chosen/snap-hud.png](mockups/chosen/snap-hud.png) | 880×580 | The snap HUD: after a shortcut, a small overlay names the position and the current step in the size cycle. |
| [mockups/chosen/menu-bar-layout-grid.png](mockups/chosen/menu-bar-layout-grid.png) | 420×580 | Menu bar panel: a grid of positions for moving the front window with one click, plus the size cycle and display buttons. |
| [mockups/chosen/first-run-try-it.png](mockups/chosen/first-run-try-it.png) | 640×580 | First-run tour: after Accessibility access is granted, it asks you to try a shortcut and shows the result. |

## Other directions explored (mockups)

Kept to show the design process. None of these were built.

| File | Direction |
|---|---|
| [mockups/explored/a-native-menu.png](mockups/explored/a-native-menu.png) | A · Native: classic menu bar menu |
| [mockups/explored/a-native-settings.png](mockups/explored/a-native-settings.png) | A · Native: System Settings style shortcuts page |
| [mockups/explored/a-native-first-run.png](mockups/explored/a-native-first-run.png) | A · Native: Accessibility permission step |
| [mockups/explored/c-popover.png](mockups/explored/c-popover.png) | C · Menu bar only: popover with inline shortcut editing |
| [mockups/explored/c-popover-first-run.png](mockups/explored/c-popover-first-run.png) | C · Menu bar only: first run inside the popover |
| [mockups/explored/d-command-palette.png](mockups/explored/d-command-palette.png) | D · Keyboard first: command palette |
| [mockups/explored/d-compact-settings.png](mockups/explored/d-compact-settings.png) | D · Keyboard first: dense settings list |
| [mockups/explored/d-first-run-card.png](mockups/explored/d-first-run-card.png) | D · Keyboard first: first-run card |

## Credit

Lens started from Spectacle's code, created by Eric Czarny, and is distributed under the MIT License (see [LICENSE.md](../../LICENSE.md)). The original Spectacle icons and artwork were designed by Iiro Jäppinen; none of them appear here.

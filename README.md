# Sequencer

A lightweight macOS timer app built with SwiftUI.

## Features

- **Floating window** — always stays on top of other windows with a translucent (vibrancy) background.
- **Sequence editor** — write one timer per line. Each line is parsed into a title and a duration. Optionally include a URL that is opened automatically when that timer starts.
  - Format: `<title> <duration> [url]`
  - Examples:
    ```
    Work on report 25m
    Take a break 5m https://youtube.com
    Review emails 10m
    Stand up / stretch 1m
    ```
  - Supported duration formats: `10m`, `1h`, `1h30m`, `90s`, `1h30m45s`
- **Multiple tabs** — save several named sequences and switch between them instantly. Double-click a tab to rename it; right-click for a context menu with rename/remove options.
- **Sound effects** — plays a chime when each timer starts and a completion sound when it finishes.
- **Auto-advance** — when one timer finishes the next one starts automatically.

## Building

1. Open `Sequencer/Sequencer.xcodeproj` in **Xcode 15** or later.
2. Select the **Sequencer** scheme and your Mac as the run destination.
3. Press **⌘R** to build and run.

Requires **macOS 13.0 (Ventura)** or later.
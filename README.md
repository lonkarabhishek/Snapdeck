# Barkit

A collection of lightweight macOS menu bar tools. Built with Swift, no Xcode required.

## The Tools

### Snapdeck — Screenshot Manager
Recent screenshots one click away in the menu bar. Floating thumbnail on capture, one-click copy, drag and drop.
```bash
curl -sL https://raw.githubusercontent.com/lonkarabhishek/Snapdeck/main/get.sh | bash -s Snapdeck
```

### KleepMe — Clipboard History
You copy a link, then copy some text, and the link is gone forever. KleepMe keeps your last 20 copied items — text, images, links. Pin favorites, search history.
```bash
curl -sL https://raw.githubusercontent.com/lonkarabhishek/Snapdeck/main/get.sh | bash -s KleepMe
```

### QuickScrap — Instant Scratchpad
Need to jot down a phone number or tracking ID? Opening Notes feels heavy. QuickScrap is a scratchpad that's always one click away. No titles, no folders, no syncing.
```bash
curl -sL https://raw.githubusercontent.com/lonkarabhishek/Snapdeck/main/get.sh | bash -s QuickScrap
```

### TextGrab — Screen OCR
You see text in an image, a video, a non-selectable part of a website. You can't copy it. TextGrab lets you draw a box around anything on screen and extracts the text instantly.
```bash
curl -sL https://raw.githubusercontent.com/lonkarabhishek/Snapdeck/main/get.sh | bash -s TextGrab
```

### CleanDock — Downloads Cleaner
Your Downloads folder has 400 files from 2 years ago. CleanDock shows recent downloads, lets you drag them where they belong, and auto-cleans anything older than 30 days.
```bash
curl -sL https://raw.githubusercontent.com/lonkarabhishek/Snapdeck/main/get.sh | bash -s CleanDock
```

### DropShelf — Drag & Drop Shelf
Dragging a file between apps on Mac feels like carrying a pizza through a revolving door. DropShelf is a menu bar shelf where you can park files, images, and text mid-drag — and grab them whenever.
```bash
curl -sL https://raw.githubusercontent.com/lonkarabhishek/Snapdeck/main/get.sh | bash -s DropShelf
```

## Build from Source

Requires macOS 13+ and Xcode Command Line Tools.

```bash
git clone https://github.com/lonkarabhishek/Snapdeck.git
cd Snapdeck

# Build any app
./Snapdeck/build.sh      # or just ./build.sh for Snapdeck
./KleepMe/build.sh
./QuickScrap/build.sh
./TextGrab/build.sh
./CleanDock/build.sh
./DropShelf/build.sh
```

## How It Works

- Pure Swift, compiled with `swiftc` — no Xcode project needed
- Each app is a standalone menu bar agent (no dock icon)
- ~400–600 lines of code per app
- macOS 13+ using AppKit, SwiftUI, and native frameworks (Vision for OCR, DispatchSource for file watching)

## License

MIT

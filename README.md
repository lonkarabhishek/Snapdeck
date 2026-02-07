# ScreenshotGrabber

A lightweight macOS menu bar app that keeps your recent screenshots one click away.

macOS shows a brief thumbnail when you take a screenshot, but it disappears quickly. ScreenshotGrabber solves that by:

- Showing recent screenshots in a **menu bar dropdown**
- Displaying a **floating thumbnail** when a new screenshot is taken (stays visible longer)
- **One-click copy** to clipboard from either surface
- **Drag and drop** screenshots from the menu into any app

## Install

1. Download **ScreenshotGrabber.zip** from the [latest release](https://github.com/lonkarabhishek/Snapdeck/releases/latest)
2. Unzip and drag **ScreenshotGrabber.app** to your Applications folder
3. Double-click to open

> **First launch:** macOS will show a warning because the app isn't signed with an Apple Developer certificate. This is normal for open-source apps.
>
> To open it: **Right-click** the app → click **Open** → click **Open** again in the dialog. You only need to do this once.

## Usage

- **Menu bar icon** — Click the camera icon in your menu bar to see recent screenshots
- **Floating thumbnail** — When you take a screenshot, a thumbnail appears at the bottom-right of your screen
  - **Click** to copy to clipboard
  - **Drag** to reposition it
  - It auto-dismisses after 5 seconds (hover to keep it visible)
- **Screenshot list** — Click any row to copy, or right-click for more options
  - Copy to Clipboard
  - Show in Finder
  - Drag and drop into any app
- **Quit** — Click the menu bar icon and hit "Quit" at the bottom

## Build from Source

Requires macOS 13+ and Xcode Command Line Tools.

```bash
git clone https://github.com/lonkarabhishek/Snapdeck.git
cd ScreenshotGrabber
./build.sh
open ScreenshotGrabber.app
```

## How It Works

- Detects your screenshot save location via `defaults read com.apple.screencapture location` (falls back to ~/Desktop)
- Watches the directory for new `.png` files using `DispatchSource`
- Keeps the last 20 screenshots in memory
- Runs as a menu bar agent (no dock icon)

## License

MIT

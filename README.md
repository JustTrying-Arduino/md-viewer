# MD Viewer

A native Markdown viewer and editor for macOS. Clean modern UI inspired by Obsidian's reading mode, built entirely in SwiftUI.

<!-- screenshots go here -->

## Features

- Live preview with GitHub-flavored Markdown
- Toggle between rendered preview and plain-text editor (`⌘E`)
- Syntax-highlighted code blocks (Splash)
- KaTeX math (`$$ … $$`)
- Mermaid diagrams
- GFM tables, task lists, footnotes, blockquotes
- Light & dark mode (follows the system)
- Outline sidebar with click-to-scroll
- Browse sibling `.md` files in the same folder
- Live reload when the file changes on disk
- Drag & drop, multi-window (one window per file)

## Build & install

Requires **macOS 14+**, **Xcode 15+**, and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
brew install xcodegen
git clone https://github.com/JustTrying-Arduino/md-viewer.git
cd md-viewer
xcodegen generate
xcodebuild -project "MD Viewer.xcodeproj" \
           -scheme "MD Viewer" \
           -configuration Release \
           -derivedDataPath build
cp -R "build/Build/Products/Release/MD Viewer.app" /Applications/
```

To register the app as the default `.md` / `.markdown` handler in Finder:

```bash
/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister -f "/Applications/MD Viewer.app"
```

## Keyboard shortcuts

| Shortcut | Action |
| -------- | ------ |
| `⌘O`     | Open file |
| `⌘S`     | Save |
| `⌘E`     | Toggle preview / editor |

## Stack

Swift 5.9 · SwiftUI · [MarkdownUI](https://github.com/gonzalezreal/swift-markdown-ui) · [Splash](https://github.com/JohnSundell/Splash) · KaTeX · Mermaid (assets bundled, no CDN at runtime).

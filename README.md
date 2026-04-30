# MD Viewer

A native Markdown viewer and editor for macOS. Clean modern UI inspired by Obsidian's reading mode, built entirely in SwiftUI.

<!-- screenshots go here -->

## Features

### Working with a document

- Toggle between rendered preview and plain-text editor (`⌘E`)
- Outline sidebar with click-to-scroll — navigate the document's structure
- Browse sibling `.md` files in the same folder — jump between docs without leaving the window

### Rendering & UX

- Live preview with GitHub-flavored Markdown
- Syntax-highlighted code blocks (Splash)
- KaTeX math (`$$ … $$`)
- Mermaid diagrams
- GFM tables, task lists, footnotes, blockquotes
- Light & dark mode (follows the system)
- Live reload when the file changes on disk
- Drag & drop, multi-window (one window per file)

## Install

### Download (recommended)

Grab the latest `.app` directly from the [Releases page](https://github.com/JustTrying-Arduino/md-viewer/releases/latest):

1. Download `MD-Viewer-x.y.z.zip`
2. Unzip and move `MD Viewer.app` into `/Applications`
3. First launch: right-click the app → **Open** (the build is ad-hoc signed, not notarized)

Requires **macOS 14+**.

### Build from source

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

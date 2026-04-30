# Welcome to MD Viewer

A native Markdown reader for macOS — clean, fast, and built entirely in SwiftUI.

> "Documentation should feel like reading, not parsing." — every developer, eventually.

## Why another viewer?

Most Markdown tools fall into two camps: heavyweight editors that try to be IDEs, or browser-based previewers that load CDN assets and fight your scroll. MD Viewer is neither. It's a **focused reading mode** for the `.md` files you already have on disk, with just enough editing to fix a typo without context-switching.

## What you'll like

- **Typography first.** Generous line height, comfortable measure, real headings hierarchy.
- **Light & dark, automatic.** Follows your system theme — no settings panel to find.
- **Zero network.** KaTeX, Mermaid, and syntax themes are bundled. Open a file on a plane.
- **Multi-window.** One file per window, the way macOS apps used to work.
- **Drag, drop, double-click.** Set MD Viewer as your default `.md` handler and forget it exists.

## A taste of the rendering

Inline things look the way you'd expect: **bold**, *italic*, ~~strikethrough~~, `inline code`, and [links to elsewhere](https://example.com).

> Block quotes get a soft accent stripe and a touch of indentation, so they don't visually shout — they just sit a little to the side, like an aside in a book.

### Lists nest cleanly

1. Top-level item with a sentence that runs long enough to wrap, just to make sure the indentation holds when the line breaks.
2. Another item.
   - Nested bullet
   - Another nested bullet, with a [link](https://example.com)
3. Final item.

### Task lists work too

- [x] Open the file
- [x] Read it
- [ ] Close the laptop and go for a walk

---

Open the **outline** sidebar (top-left toolbar) to jump between sections, or the **folder** button (bottom-left) to browse other `.md` files in the same directory. That's the whole UI.

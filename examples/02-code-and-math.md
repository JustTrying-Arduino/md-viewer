# Code & Math

This document exercises the technical bits: syntax-highlighted code blocks, inline and block math, and tables. Everything renders offline — no CDN at runtime.

## Syntax highlighting

MD Viewer uses [Splash](https://github.com/JohnSundell/Splash) for Swift, with sensible fallbacks for the usual suspects.

### Swift

```swift
struct DocumentViewModel {
    var url: URL?
    var rawText: String = ""

    mutating func load(_ url: URL) throws {
        rawText = try String(contentsOf: url, encoding: .utf8)
        self.url = url
    }
}

let vm = DocumentViewModel()
print(vm.url ?? "no document")
```

### TypeScript

```typescript
type Result<T, E = Error> =
  | { ok: true; value: T }
  | { ok: false; error: E };

async function fetchUser(id: string): Promise<Result<User>> {
  try {
    const value = await api.get(`/users/${id}`);
    return { ok: true, value };
  } catch (error) {
    return { ok: false, error: error as Error };
  }
}
```

### Python

```python
from dataclasses import dataclass
from typing import Iterable

@dataclass(frozen=True)
class Point:
    x: float
    y: float

def centroid(points: Iterable[Point]) -> Point:
    pts = list(points)
    n = len(pts)
    return Point(
        x=sum(p.x for p in pts) / n,
        y=sum(p.y for p in pts) / n,
    )
```

### Shell

```bash
# Build, install, register as default .md handler
xcodegen generate
xcodebuild -scheme "MD Viewer" -configuration Release -derivedDataPath build
cp -R "build/Build/Products/Release/MD Viewer.app" /Applications/
```

## Math with KaTeX

Inline: the area of a circle is $A = \pi r^2$, and Euler's identity $e^{i\pi} + 1 = 0$ ties five constants together.

Block-level equations get their own breathing room:

$$
\hat{f}(\xi) = \int_{-\infty}^{\infty} f(x)\, e^{-2\pi i x \xi}\, dx
$$

A classic gradient descent step:

$$
\theta_{t+1} = \theta_t - \eta \nabla_\theta \mathcal{L}(\theta_t)
$$

And the Cauchy–Schwarz inequality, because why not:

$$
\left| \langle u, v \rangle \right|^2 \;\leq\; \langle u, u \rangle \cdot \langle v, v \rangle
$$

## Tables

GFM tables align cleanly:

| Feature              | Engine        | Bundled | Notes                        |
| -------------------- | ------------- | :-----: | ---------------------------- |
| Markdown parsing     | MarkdownUI    |   ✅    | GitHub-flavored              |
| Code highlighting    | Splash        |   ✅    | Swift-first, others via CSS  |
| Math                 | KaTeX         |   ✅    | Inline `$…$` and block `$$…$$` |
| Diagrams             | Mermaid       |   ✅    | See next document            |
| Live reload          | DispatchSource |  ✅    | Watches the file on disk     |

## Inline `code` vs blocks

Mention `git rebase --interactive` inline and it stays in the line. Wrap it in a fence and it gets its own card with a language label and selectable text.

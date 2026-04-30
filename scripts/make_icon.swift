#!/usr/bin/env swift
//
// Generates the 10 PNGs required for an AssetCatalog AppIcon at all the
// macOS sizes (16, 32, 64, 128, 256, 512, 1024).
//
// Usage:
//   swift scripts/make_icon.swift "MD Viewer/Assets.xcassets/AppIcon.appiconset"
//
// The icon is a vertical purple gradient squircle with a bold white "M".
// Tweak the colors / glyph below to taste.
//

import AppKit

// MARK: - Design knobs

let topColor    = NSColor(red: 0.66, green: 0.55, blue: 0.97, alpha: 1.0) // light purple
let bottomColor = NSColor(red: 0.46, green: 0.28, blue: 0.93, alpha: 1.0) // deeper purple
let glyph       = "M"
let glyphWeightFraction: CGFloat = 0.62  // fontSize = size * fraction

// MARK: - Drawing

func makeIcon(pixels: Int) -> NSBitmapImageRep {
    let size = CGFloat(pixels)

    let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels, pixelsHigh: pixels,
        bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB,
        bitmapFormat: [],
        bytesPerRow: 0, bitsPerPixel: 0
    )!

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)

    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let cornerRadius = size * 0.2237 // macOS Big Sur+ squircle approximation
    let squircle = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)

    // Clip to squircle so anti-aliasing is clean at all sizes.
    squircle.addClip()

    // Vertical gradient.
    let gradient = NSGradient(colors: [topColor, bottomColor])!
    gradient.draw(in: rect, angle: 270)

    // Soft top highlight for a hint of depth (Big Sur style).
    let highlight = NSBezierPath()
    highlight.move(to: NSPoint(x: 0, y: size))
    highlight.line(to: NSPoint(x: size, y: size))
    highlight.line(to: NSPoint(x: size, y: size * 0.62))
    highlight.curve(
        to: NSPoint(x: 0, y: size * 0.62),
        controlPoint1: NSPoint(x: size * 0.72, y: size * 0.86),
        controlPoint2: NSPoint(x: size * 0.28, y: size * 0.86)
    )
    highlight.close()
    NSColor.white.withAlphaComponent(0.07).setFill()
    highlight.fill()

    // Bold white glyph.
    let fontSize = size * glyphWeightFraction
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: fontSize, weight: .black),
        .foregroundColor: NSColor.white,
        .kern: NSNumber(value: 0)
    ]
    let str = NSAttributedString(string: glyph, attributes: attrs)
    let strSize = str.size()
    let origin = NSPoint(
        x: (size - strSize.width) / 2,
        y: (size - strSize.height) / 2 - size * 0.04 // optical centering nudge
    )
    str.draw(at: origin)

    NSGraphicsContext.restoreGraphicsState()
    return bitmap
}

// MARK: - Main

guard CommandLine.arguments.count >= 2 else {
    fputs("Usage: \(CommandLine.arguments[0]) <output appiconset dir>\n", stderr)
    exit(1)
}

let outDir = URL(fileURLWithPath: CommandLine.arguments[1])
try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

let entries: [(name: String, px: Int)] = [
    ("icon_16x16",       16),
    ("icon_16x16@2x",    32),
    ("icon_32x32",       32),
    ("icon_32x32@2x",    64),
    ("icon_128x128",    128),
    ("icon_128x128@2x", 256),
    ("icon_256x256",    256),
    ("icon_256x256@2x", 512),
    ("icon_512x512",    512),
    ("icon_512x512@2x", 1024),
]

for (name, px) in entries {
    let bmp = makeIcon(pixels: px)
    guard let png = bmp.representation(using: .png, properties: [:]) else {
        fputs("✗ \(name): PNG encode failed\n", stderr)
        continue
    }
    let url = outDir.appendingPathComponent("\(name).png")
    try png.write(to: url)
    print("✓ \(name).png  (\(px)×\(px))")
}

// Write the AssetCatalog Contents.json so each PNG is referenced.
let contents: [String: Any] = [
    "info": ["author": "xcode", "version": 1],
    "images": entries.map { entry -> [String: String] in
        // entry.name is e.g. "icon_16x16@2x" → size "16x16", scale "2x".
        let parts = entry.name.replacingOccurrences(of: "icon_", with: "").components(separatedBy: "@")
        let size = parts[0]
        let scale = parts.count > 1 ? parts[1] : "1x"
        return [
            "idiom": "mac",
            "size": size,
            "scale": scale,
            "filename": "\(entry.name).png"
        ]
    }
]
let contentsURL = outDir.appendingPathComponent("Contents.json")
let json = try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
try json.write(to: contentsURL)
print("✓ Contents.json updated")

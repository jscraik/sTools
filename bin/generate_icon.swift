#!/usr/bin/env swift
import AppKit

let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)

image.lockFocus()

let rect = NSRect(origin: .zero, size: size)
let tileRect = rect.insetBy(dx: 100, dy: 100)
let cornerRadius: CGFloat = 232

// Modern dark background - matching brand logo depths
let backgroundPath = NSBezierPath(roundedRect: tileRect, xRadius: cornerRadius, yRadius: cornerRadius)

let topColor = NSColor(calibratedRed: 44.0/255.0, green: 62.0/255.0, blue: 80.0/255.0, alpha: 1.0)     // Dark charcoal
let bottomColor = NSColor(calibratedRed: 20.0/255.0, green: 30.0/255.0, blue: 40.0/255.0, alpha: 1.0) // Deep black

let gradient = NSGradient(starting: topColor, ending: bottomColor)!
gradient.draw(in: backgroundPath, angle: -45)

// Lime green highlight on top edge - brand signature color
let highlightPath = NSBezierPath(roundedRect: tileRect.insetBy(dx: 6, dy: 6), xRadius: cornerRadius - 6, yRadius: cornerRadius - 6)
NSColor(calibratedRed: 162.0/255.0, green: 208.0/255.0, blue: 51.0/255.0, alpha: 0.4).setStroke()
highlightPath.lineWidth = 4
highlightPath.stroke()

// Deeper shadow for depth
let glyphShadow = NSShadow()
glyphShadow.shadowBlurRadius = 32
glyphShadow.shadowOffset = NSSize(width: 0, height: -10)
glyphShadow.shadowColor = NSColor.black.withAlphaComponent(0.5)

// Draw toolbox glyph (briefcase.fill)
let symbolConfig = NSImage.SymbolConfiguration(pointSize: 450, weight: .semibold)
    .applying(NSImage.SymbolConfiguration(paletteColors: [NSColor(calibratedRed: 162.0/255.0, green: 208.0/255.0, blue: 51.0/255.0, alpha: 1.0)])) // Brand Green

if let symbol = NSImage(systemSymbolName: "briefcase.fill", accessibilityDescription: nil)?
    .withSymbolConfiguration(symbolConfig) {
    
    let targetRect = tileRect.insetBy(dx: 150, dy: 150)
    let symbolSize = symbol.size
    let scale = min(targetRect.width / symbolSize.width, targetRect.height / symbolSize.height)
    let scaledSize = NSSize(width: symbolSize.width * scale, height: symbolSize.height * scale)
    let drawRect = NSRect(
        x: targetRect.midX - scaledSize.width / 2,
        y: targetRect.midY - scaledSize.height / 2,
        width: scaledSize.width,
        height: scaledSize.height
    )
    
    NSGraphicsContext.saveGraphicsState()
    glyphShadow.set()
    symbol.draw(in: drawRect, from: .zero, operation: .sourceOver, fraction: 1.0)
    NSGraphicsContext.restoreGraphicsState()
}

// Add a blue wrench badge to represent 'Tools'
let badgeSize: CGFloat = 220
let badgeRect = NSRect(
    x: tileRect.maxX - badgeSize - 80,
    y: tileRect.minY + 80,
    width: badgeSize,
    height: badgeSize
)

// Wrench in brand blue
let wrenchConfig = NSImage.SymbolConfiguration(pointSize: 120, weight: .bold)
    .applying(NSImage.SymbolConfiguration(paletteColors: [NSColor(calibratedRed: 52.0/255.0, green: 152.0/255.0, blue: 219.0/255.0, alpha: 1.0)])) // Brand Blue

if let wrench = NSImage(systemSymbolName: "wrench.fill", accessibilityDescription: nil)?
    .withSymbolConfiguration(wrenchConfig) {
    
    let wrenchSize = wrench.size
    let wrenchRect = NSRect(
        x: badgeRect.midX - wrenchSize.width / 2,
        y: badgeRect.midY - wrenchSize.height / 2,
        width: wrenchSize.width,
        height: wrenchSize.height
    )
    
    NSGraphicsContext.saveGraphicsState()
    let wrenchShadow = NSShadow()
    wrenchShadow.shadowBlurRadius = 15
    wrenchShadow.shadowOffset = NSSize(width: 0, height: -5)
    wrenchShadow.shadowColor = NSColor.black.withAlphaComponent(0.4)
    wrenchShadow.set()
    
    wrench.draw(in: wrenchRect, from: .zero, operation: .sourceOver, fraction: 1.0)
    NSGraphicsContext.restoreGraphicsState()
}

image.unlockFocus()

// Save as PNG
let pngData = image.tiffRepresentation.flatMap { NSBitmapImageRep(data: $0) }?.representation(using: .png, properties: [:])

if let data = pngData {
    let url = URL(fileURLWithPath: "Icon.png")
    try? data.write(to: url)
    print("Icon.png generated at \(url.path)")
} else {
    print("Failed to generate icon")
    exit(1)
}

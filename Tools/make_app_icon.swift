#!/usr/bin/env swift
// Renders the AzBar app icon (three opaque 1024x1024 PNGs) into the AppIcon asset set.
// Run from the repository root:  swift Tools/make_app_icon.swift
import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

let size = 1024
let text = "از بر"
let fontURL = URL(fileURLWithPath: "AzBar/Resources/Fonts/NotoNastaliqUrdu-Regular.ttf")
let outDir = "AzBar/Resources/Assets.xcassets/AppIcon.appiconset"

struct Variant {
    let file: String
    let top: UInt32
    let bottom: UInt32
    let ink: UInt32
    let glow: UInt32?
}

let variants = [
    Variant(file: "AppIcon.png", top: 0x14838F, bottom: 0x0A4F57, ink: 0xFBF6EA, glow: 0x3FB4BF),
    Variant(file: "AppIcon-Dark.png", top: 0x123236, bottom: 0x061416, ink: 0x4FC3C9, glow: 0x1E5A60),
    Variant(file: "AppIcon-Tinted.png", top: 0x000000, bottom: 0x000000, ink: 0xFFFFFF, glow: nil),
]

let space = CGColorSpace(name: CGColorSpace.sRGB)!

func color(_ hex: UInt32, alpha: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: space, components: [
        CGFloat((hex >> 16) & 0xFF) / 255, CGFloat((hex >> 8) & 0xFF) / 255, CGFloat(hex & 0xFF) / 255, alpha,
    ])!
}

guard let descriptors = CTFontManagerCreateFontDescriptorsFromURL(fontURL as CFURL) as? [CTFontDescriptor],
      let descriptor = descriptors.first else {
    FileHandle.standardError.write(Data("cannot load font at \(fontURL.path)\n".utf8))
    exit(1)
}

func makeLine(fontSize: CGFloat, ink: CGColor) -> CTLine {
    let font = CTFontCreateWithFontDescriptor(descriptor, fontSize, nil)
    let attrs: [CFString: Any] = [
        kCTFontAttributeName: font,
        kCTForegroundColorAttributeName: ink,
    ]
    return CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: attrs as [NSAttributedString.Key: Any]))
}

let maxWidth: CGFloat = 660
let maxHeight: CGFloat = 600

func render(_ v: Variant) {
    let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                        space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    let rect = CGRect(x: 0, y: 0, width: size, height: size)

    // Background gradient (top to bottom).
    let gradient = CGGradient(colorsSpace: space, colors: [color(v.top), color(v.bottom)] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: size), end: CGPoint(x: 0, y: 0), options: [])

    // Subtle radial glow behind the text.
    if let glow = v.glow {
        let g = CGGradient(colorsSpace: space, colors: [color(glow, alpha: 0.55), color(glow, alpha: 0)] as CFArray, locations: [0, 1])!
        ctx.drawRadialGradient(g, startCenter: CGPoint(x: 512, y: 540), startRadius: 0,
                               endCenter: CGPoint(x: 512, y: 540), endRadius: 560, options: [])
    }

    // Fit the text.
    let ink = color(v.ink)
    var fontSize: CGFloat = 420
    var line = makeLine(fontSize: fontSize, ink: ink)
    var bounds = CTLineGetImageBounds(line, ctx)
    while (bounds.width > maxWidth || bounds.height > maxHeight) && fontSize > 20 {
        fontSize -= 4
        line = makeLine(fontSize: fontSize, ink: ink)
        bounds = CTLineGetImageBounds(line, ctx)
    }

    // Optically centre on the ink bounds.
    let x = rect.midX - bounds.midX
    let y = rect.midY - bounds.midY

    // Soft shadow for depth (skipped for tinted).
    if v.glow != nil {
        ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 24, color: color(0x000000, alpha: 0.35))
    }
    ctx.textPosition = CGPoint(x: x, y: y)
    CTLineDraw(line, ctx)
    print("\(v.file): font \(fontSize) ink \(Int(bounds.width))x\(Int(bounds.height))")

    let url = URL(fileURLWithPath: outDir).appendingPathComponent(v.file)
    let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, ctx.makeImage()!, nil)
    guard CGImageDestinationFinalize(dest) else {
        FileHandle.standardError.write(Data("failed to write \(url.path)\n".utf8))
        exit(1)
    }
}

variants.forEach(render)

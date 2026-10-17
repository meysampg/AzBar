#!/usr/bin/env swift
// Renders the AzBar README poster (docs/poster.png + docs/poster.jpg), 2400x1600.
// Deterministic: CoreGraphics + CoreText + ImageIO only, seeded RNG, no network.
// Run from the repository root:  swift Tools/make_poster.swift [--debug]
import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

let debug = CommandLine.arguments.contains("--debug")
let W: CGFloat = 2400, Hh: CGFloat = 1600
let space = CGColorSpace(name: CGColorSpace.sRGB)!

func Y(_ y: CGFloat) -> CGFloat { Hh - y }
func P(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: Hh - y) }
func color(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: space, components: [
        CGFloat((hex >> 16) & 0xFF) / 255, CGFloat((hex >> 8) & 0xFF) / 255, CGFloat(hex & 0xFF) / 255, a])!
}
let paper: UInt32 = 0xFBF7EF, teal: UInt32 = 0x0F6E78, tealLight: UInt32 = 0x157F89, tealDark: UInt32 = 0x0A4F57
let tealNight: UInt32 = 0x062A2F, gold: UInt32 = 0xC9A227, goldLight: UInt32 = 0xF1D98A, goldGlow: UInt32 = 0xF5D06A
let goldDeep: UInt32 = 0x8A6A10, goldShade: UInt32 = 0x5E470A, ink: UInt32 = 0x1F2A2E, bezel: UInt32 = 0x101315

func grad(_ stops: [(UInt32, CGFloat, CGFloat)]) -> CGGradient {
    CGGradient(colorsSpace: space, colors: stops.map { color($0.0, $0.1) } as CFArray, locations: stops.map { $0.2 })!
}

// Seeded RNG
var seed: UInt64 = 1404
func rnd() -> CGFloat {
    seed = seed &* 6364136223846793005 &+ 1442695040888963407
    return CGFloat(Double(seed >> 11) / 9007199254740992)
}

// Fonts
func loadDesc(_ path: String) -> CTFontDescriptor {
    guard let ds = CTFontManagerCreateFontDescriptorsFromURL(URL(fileURLWithPath: path) as CFURL) as? [CTFontDescriptor],
          let d = ds.first else { FileHandle.standardError.write(Data("cannot load \(path)\n".utf8)); exit(1) }
    return d
}
let nastaliq = loadDesc("AzBar/Resources/Fonts/NotoNastaliqUrdu-Regular.ttf")
let vzSemi = loadDesc("AzBar/Resources/Fonts/Vazirmatn-SemiBold.ttf")
let vzMed = loadDesc("AzBar/Resources/Fonts/Vazirmatn-Medium.ttf")

func shape(_ s: String, _ d: CTFontDescriptor, _ size: CGFloat, kern: CGFloat = 0) -> CGPath {
    let font = CTFontCreateWithFontDescriptor(d, size, nil)
    var attrs: [NSAttributedString.Key: Any] = [NSAttributedString.Key(kCTFontAttributeName as String): font]
    if kern != 0 { attrs[NSAttributedString.Key(kCTKernAttributeName as String)] = kern }
    let line = CTLineCreateWithAttributedString(NSAttributedString(string: s, attributes: attrs))
    let path = CGMutablePath()
    for run in CTLineGetGlyphRuns(line) as! [CTRun] {
        let n = CTRunGetGlyphCount(run)
        var glyphs = [CGGlyph](repeating: 0, count: n)
        var pos = [CGPoint](repeating: .zero, count: n)
        CTRunGetGlyphs(run, CFRange(location: 0, length: 0), &glyphs)
        CTRunGetPositions(run, CFRange(location: 0, length: 0), &pos)
        let attrs = CTRunGetAttributes(run) as! [String: Any]
        let rf = attrs[kCTFontAttributeName as String] as! CTFont
        for i in 0..<n {
            if let gp = CTFontCreatePathForGlyph(rf, glyphs[i], nil) {
                path.addPath(gp, transform: CGAffineTransform(translationX: pos[i].x, y: pos[i].y))
            }
        }
    }
    return path
}
/// Nastaliq (or any) text fitted into maxW x maxH and centred on (cx, cy) by glyph-path bounds.
func fitted(_ s: String, _ d: CTFontDescriptor, maxW: CGFloat, maxH: CGFloat, cx: CGFloat, cy: CGFloat) -> CGPath {
    let b = shape(s, d, 100).boundingBoxOfPath
    let size = 100 * min(maxW / b.width, maxH / b.height)
    let p = shape(s, d, size)
    let bb = p.boundingBoxOfPath
    return p.copy(using: [CGAffineTransform(translationX: cx - bb.midX, y: Y(cy) - bb.midY)])!
}
/// UI text: horizontally centred on cx, baseline at spec y `base`.
func uiText(_ s: String, _ d: CTFontDescriptor, size: CGFloat, cx: CGFloat, base: CGFloat, kern: CGFloat = 0) -> CGPath {
    let p = shape(s, d, size, kern: kern)
    let bb = p.boundingBoxOfPath
    return p.copy(using: [CGAffineTransform(translationX: cx - bb.midX, y: Y(base))])!
}

let ctx = CGContext(data: nil, width: Int(W), height: Int(Hh), bitsPerComponent: 8, bytesPerRow: 0,
                    space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
ctx.setLineJoin(.round); ctx.setLineCap(.round)

func star(_ cx: CGFloat, _ cy: CGFloat, n: Int, ro: CGFloat, ri: CGFloat, rot: CGFloat = 0) -> CGPath {
    let p = CGMutablePath()
    for k in 0..<(2 * n) {
        let a = rot + CGFloat(k) * .pi / CGFloat(n) - .pi / 2
        let r = k % 2 == 0 ? ro : ri
        let pt = P(cx + r * cos(a), cy + r * sin(a))
        if k == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
    }
    p.closeSubpath(); return p
}
func khatam(_ cx: CGFloat, _ cy: CGFloat, ro: CGFloat) -> CGPath {
    let p = CGMutablePath()
    for k in 0..<16 {
        let a = CGFloat(k) * 22.5 * .pi / 180
        let r = k % 2 == 0 ? ro : ro * 0.7654
        let pt = P(cx + r * cos(a), cy + r * sin(a))
        if k == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
    }
    p.closeSubpath(); return p
}
func fillPath(_ p: CGPath, _ c: CGColor) { ctx.addPath(p); ctx.setFillColor(c); ctx.fillPath() }
func strokePath(_ p: CGPath, _ c: CGColor, _ w: CGFloat) {
    ctx.addPath(p); ctx.setStrokeColor(c); ctx.setLineWidth(w); ctx.strokePath()
}
func circle(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) -> CGPath {
    CGPath(ellipseIn: CGRect(x: cx - r, y: Y(cy) - r, width: 2 * r, height: 2 * r), transform: nil)
}
func rrect(_ x0: CGFloat, _ y0: CGFloat, _ x1: CGFloat, _ y1: CGFloat, _ r: CGFloat) -> CGPath {
    CGPath(roundedRect: CGRect(x: x0, y: Y(y1), width: x1 - x0, height: y1 - y0), cornerWidth: r, cornerHeight: r, transform: nil)
}
func strokedFill(_ p: CGPath, width: CGFloat, gradient g: CGGradient, from: CGPoint, to: CGPoint) {
    ctx.saveGState()
    ctx.addPath(p.copy(strokingWithWidth: width, lineCap: .round, lineJoin: .round, miterLimit: 4))
    ctx.clip()
    ctx.drawLinearGradient(g, start: from, end: to, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    ctx.restoreGState()
}
func fillGradient(_ p: CGPath, _ g: CGGradient, from: CGPoint, to: CGPoint) {
    ctx.saveGState(); ctx.addPath(p); ctx.clip()
    ctx.drawLinearGradient(g, start: from, end: to, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    ctx.restoreGState()
}
let goldGrad = grad([(goldLight, 1, 0), (gold, 1, 0.5), (goldDeep, 1, 1)])

func sparkle(_ x: CGFloat, _ y: CGFloat, _ R: CGFloat, _ rot: CGFloat, _ a: CGFloat) {
    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: 2 * R, color: color(goldGlow, a))
    fillPath(star(x, y, n: 4, ro: R, ri: R * 0.28, rot: rot), color(goldGlow, a))
    ctx.restoreGState()
}

// ---------------------------------------------------------------- 1. Background
ctx.drawRadialGradient(grad([(tealLight, 1, 0), (tealDark, 1, 700 / 1500), (tealNight, 1, 1)]),
                       startCenter: P(1200, 820), startRadius: 0, endCenter: P(1200, 820), endRadius: 1500,
                       options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
// Khatam tessellation
for j in 0...14 { for i in 0...20 {
    let p = khatam(CGFloat(i) * 120, CGFloat(j) * 120, ro: 60)
    if (i + j) % 2 == 0 { fillPath(p, color(gold, 0.035)) }
    ctx.setLineWidth(1.5); strokePath(p, color(gold, 0.10), 1.5)
} }
// Rays + glow
for k in 0..<36 {
    let a = CGFloat(k) * 10 * .pi / 180, hw = 2 * CGFloat.pi / 180
    let w = CGMutablePath()
    w.move(to: P(1200, 900))
    for s in 0...8 {
        let t = a - hw + 2 * hw * CGFloat(s) / 8
        w.addLine(to: P(1200 + 1500 * cos(t), 900 - 1500 * sin(t)))
    }
    w.closeSubpath()
    ctx.saveGState(); ctx.addPath(w); ctx.clip()
    ctx.drawRadialGradient(grad([(goldGlow, k % 2 == 0 ? 0.20 : 0.11, 0), (goldGlow, 0, 1)]),
                           startCenter: P(1200, 900), startRadius: 0, endCenter: P(1200, 900), endRadius: 1300, options: [])
    ctx.restoreGState()
}
ctx.drawRadialGradient(grad([(goldGlow, 0.30, 0), (goldGlow, 0, 1)]),
                       startCenter: P(1200, 900), startRadius: 0, endCenter: P(1200, 900), endRadius: 620, options: [])
// Background sparkles
for _ in 0..<110 {
    let x = 70 + rnd() * 2260, y = 70 + rnd() * 1460
    let u = rnd(), r45 = rnd() < 0.5, al = 0.5 + 0.5 * rnd()
    sparkle(x, y, 4 + 10 * u * u, r45 ? .pi / 4 : 0, al)
}
for _ in 0..<25 {
    let x = 70 + rnd() * 2260, y = 70 + rnd() * 1460, R = 6 + 4 * rnd()
    let p = khatam(x, y, ro: R)
    fillPath(p, color(gold, 0.30)); strokePath(p, color(goldLight, 0.30), 0.8)
}

// ---------------------------------------------------------------- Ornament helpers
func polyPoints(_ pts: [CGPoint]) -> CGPath { // spec-space points -> path
    let p = CGMutablePath()
    for (i, q) in pts.enumerated() { if i == 0 { p.move(to: P(q.x, q.y)) } else { p.addLine(to: P(q.x, q.y)) } }
    p.closeSubpath(); return p
}
func pearls(along pts: [CGPoint], every d: CGFloat, r: CGFloat, color c: CGColor) {
    var acc: CGFloat = 0
    var prev = pts[0]
    fillPath(circle(prev.x, prev.y, r), c)
    for q in pts.dropFirst() {
        var seg = hypot(q.x - prev.x, q.y - prev.y)
        let dx = (q.x - prev.x) / max(seg, 0.0001), dy = (q.y - prev.y) / max(seg, 0.0001)
        var cur = prev
        while acc + seg >= d {
            let t = d - acc
            cur = CGPoint(x: cur.x + dx * t, y: cur.y + dy * t)
            fillPath(circle(cur.x, cur.y, r), c)
            seg -= t; acc = 0
        }
        acc += seg; prev = q
    }
}

// Cartouche (toranj) points
func cartouche(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat) -> [CGPoint] {
    var pts: [CGPoint] = []
    var deg: CGFloat = 0
    while deg < 360 {
        let t = deg * .pi / 180
        let s = 1 + 0.05 * (1 - abs(sin(12 * t)))
        pts.append(CGPoint(x: cx + rx * s * cos(t), y: cy + ry * s * sin(t)))
        deg += 0.5
    }
    return pts
}

// ---------------------------------------------------------------- 3. Top inscriptions & title
do {
    let outer = polyPoints(cartouche(1200, 176, 300, 96))
    // finials
    for dir in [CGFloat(1), CGFloat(-1)] {
        let bx = 1200 + dir * 300 * 1.05 - dir * 4
        let tear = CGMutablePath()
        tear.move(to: P(bx, 176))
        tear.addCurve(to: P(bx + dir * 44, 176), control1: P(bx + dir * 8, 176 - 20), control2: P(bx + dir * 30, 176 - 16))
        tear.addCurve(to: P(bx, 176), control1: P(bx + dir * 30, 176 + 16), control2: P(bx + dir * 8, 176 + 20))
        tear.closeSubpath()
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: -4), blur: 10, color: color(0x000000, 0.4))
        fillPath(tear, color(gold)); ctx.restoreGState()
        fillGradient(tear, goldGrad, from: P(bx, 150), to: P(bx, 200))
        strokePath(tear, color(goldDeep), 1)
        fillPath(circle(bx + dir * 48, 176, 5), color(goldLight))
        strokePath(circle(bx + dir * 48, 176, 5), color(goldDeep), 1)
    }
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -8), blur: 24, color: color(0x000000, 0.5))
    fillPath(outer, color(tealDark)); ctx.restoreGState()
    ctx.saveGState(); ctx.addPath(outer); ctx.clip()
    ctx.drawRadialGradient(grad([(teal, 1, 0), (tealDark, 1, 1)]), startCenter: P(1200, 176), startRadius: 0,
                           endCenter: P(1200, 176), endRadius: 330, options: [.drawsAfterEndLocation])
    // faint khatam inside
    for i in 0..<8 { for j in 0..<3 {
        strokePath(khatam(900 + CGFloat(i) * 60 + 30, 110 + CGFloat(j) * 60, ro: 30), color(gold, 0.10), 1)
    } }
    ctx.restoreGState()
    strokedFill(outer, width: 6, gradient: goldGrad, from: P(0, 80), to: P(0, 272))
    let inner = polyPoints(cartouche(1200, 176, 288, 84))
    strokePath(inner, color(goldLight), 1.5)
    pearls(along: cartouche(1200, 176, 288, 84) + [cartouche(1200, 176, 288, 84)[0]], every: 14, r: 2.2, color: color(gold))
}
// Title
do {
    let t = fitted("ازبر", nastaliq, maxW: 440, maxH: 168, cx: 1200, cy: 180)
    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: 40, color: color(goldGlow, 0.5))
    fillPath(t, color(goldGlow, 0.6)); ctx.restoreGState()
    let outline = t.copy(strokingWithWidth: 9, lineCap: .round, lineJoin: .round, miterLimit: 2)
    fillPath(outline, color(0x2B1E05, 0.9))
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -6), blur: 18, color: color(0x000000, 0.55))
    fillPath(t, color(0xE2B53E)); ctx.restoreGState()
    let bb = t.boundingBoxOfPath
    fillGradient(t, grad([(0xFFF1B8, 1, 0), (0xE2B53E, 1, 0.55), (0x9A7414, 1, 1)]),
                 from: CGPoint(x: 0, y: bb.maxY), to: CGPoint(x: 0, y: bb.minY))
}
// Hafez beyt panels
func katibeh(_ x0: CGFloat, _ x1: CGFloat, _ text: String) {
    let y0: CGFloat = 116, y1: CGFloat = 236
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -6), blur: 16, color: color(0x000000, 0.4))
    fillPath(rrect(x0, y0, x1, y1, 18), color(tealDark, 0.85)); ctx.restoreGState()
    strokePath(rrect(x0, y0, x1, y1, 18), color(gold), 3)
    strokePath(rrect(x0 + 8, y0 + 8, x1 - 8, y1 - 8, 12), color(goldLight), 1)
    for (sx, sy) in [(x0 + 18, y0 + 18), (x1 - 18, y0 + 18), (x0 + 18, y1 - 18), (x1 - 18, y1 - 18)] {
        let s = star(sx, sy, n: 8, ro: 12, ri: 7)
        fillPath(s, color(gold)); strokePath(s, color(goldDeep), 0.8)
    }
    let tp = fitted(text, nastaliq, maxW: 540, maxH: 70, cx: (x0 + x1) / 2, cy: (y0 + y1) / 2)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -2), blur: 4, color: color(0x000000, 0.5))
    fillPath(tp, color(paper)); ctx.restoreGState()
}
katibeh(1580, 2200, "الا یا ایها الساقی ادر کأسا و ناولها")
katibeh(200, 820, "که عشق آسان نمود اول ولی افتاد مشکل\u{200C}ها")
do {
    let tg = uiText("شعر فارسی را بیت\u{200C}به\u{200C}بیت از بر کنید", vzSemi, size: 40, cx: 1200, base: 322)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -2), blur: 6, color: color(0x000000, 0.5))
    fillPath(tg, color(paper)); ctx.restoreGState()
    let en = uiText("Memorize Persian poetry, verse by verse — Hafez · Saadi · Khayyam · Saeb", vzMed, size: 22, cx: 1200, base: 360, kern: 0.6)
    fillPath(en, color(goldLight))
}

// ---------------------------------------------------------------- 2. Phones
struct Slot { let file: String; let cx, cy, S, rot: CGFloat; let tier: Int } // tier 0 back, 1 hero, 2 front
func slot(_ f: String, _ cx: CGFloat, _ cy: CGFloat, _ S: CGFloat, _ r: CGFloat, _ t: Int) -> Slot {
    Slot(file: f, cx: cx, cy: cy, S: S, rot: r, tier: t)
}
let BL4 = slot("17-about", 215, 685, 430, -8, 0), BL3 = slot("16-settings", 390, 670, 430, -6, 0)
let BL2 = slot("15-fal-result", 565, 655, 430, -4, 0), BL1 = slot("14-fal", 740, 640, 430, -2, 0)
let BR1 = slot("07-reader", 1660, 640, 430, 2, 0), BR2 = slot("08-library", 1835, 655, 430, 4, 0)
let BR3 = slot("09-poet-7", 2010, 670, 430, 6, 0), BR4 = slot("10-category-24", 2185, 685, 430, 8, 0)
let H = slot("02-path", 1200, 960, 860, 0, 1)
let FR1 = slot("01-today", 1640, 1120, 560, 3, 2), FR2 = slot("03-learn-wordbank", 1820, 1130, 520, 5, 2)
let FR3 = slot("04-learn-fillblank", 1995, 1140, 480, 7, 2), FR4 = slot("05-learn-cloze", 2165, 1150, 440, 9, 2)
let FL1 = slot("06-lesson-complete", 760, 1120, 560, -3, 2), FL2 = slot("13-badge", 580, 1130, 520, -5, 2)
let FL3 = slot("12-progress", 405, 1140, 480, -7, 2), FL4 = slot("11-review", 235, 1150, 440, -9, 2)
var debugRects: [(CGFloat, CGFloat, CGFloat, CGFloat, CGFloat)] = []

func loadImage(_ name: String) -> CGImage {
    let u = URL(fileURLWithPath: "docs/screenshots/\(name).png")
    guard let src = CGImageSourceCreateWithURL(u as CFURL, nil), let im = CGImageSourceCreateImageAtIndex(src, 0, nil) else {
        FileHandle.standardError.write(Data("cannot load \(u.path)\n".utf8)); exit(1)
    }
    return im
}

func phone(_ s: Slot) {
    let S = s.S, sw = 0.462 * S, b = 0.032 * S, dw = sw + 2 * b, dh = S + 2 * b
    let rS = 0.105 * sw, rD = rS + b
    debugRects.append((s.cx, s.cy, dw, dh, s.rot))
    ctx.saveGState()
    ctx.translateBy(x: s.cx, y: Y(s.cy))
    ctx.rotate(by: -s.rot * .pi / 180)
    let dev = CGRect(x: -dw / 2, y: -dh / 2, width: dw, height: dh)
    let devPath = CGPath(roundedRect: dev, cornerWidth: rD, cornerHeight: rD, transform: nil)
    if s.tier == 1 {
        ctx.saveGState(); ctx.setShadow(offset: .zero, blur: 80, color: color(goldGlow, 0.65))
        fillPath(devPath, color(bezel)); ctx.restoreGState()
        ctx.saveGState(); ctx.setShadow(offset: CGSize(width: 0, height: -30), blur: 70, color: color(0x000000, 0.55))
        fillPath(devPath, color(bezel)); ctx.restoreGState()
    } else if s.tier == 2 {
        ctx.saveGState(); ctx.setShadow(offset: CGSize(width: 0, height: -22), blur: 50, color: color(0x000000, 0.5))
        fillPath(devPath, color(bezel)); ctx.restoreGState()
    } else {
        ctx.saveGState(); ctx.setShadow(offset: CGSize(width: 0, height: -12), blur: 28, color: color(0x000000, 0.35))
        fillPath(devPath, color(bezel)); ctx.restoreGState()
    }
    fillPath(devPath, color(bezel))
    strokePath(CGPath(roundedRect: dev.insetBy(dx: 1.25, dy: 1.25), cornerWidth: rD - 1.25, cornerHeight: rD - 1.25, transform: nil),
               color(gold, 0.9), 2.5)
    strokePath(CGPath(roundedRect: dev.insetBy(dx: 3.5, dy: 3.5), cornerWidth: rD - 3.5, cornerHeight: rD - 3.5, transform: nil),
               color(0x2C3236), 1)
    let scr = CGRect(x: -sw / 2, y: -S / 2, width: sw, height: S)
    ctx.saveGState()
    ctx.addPath(CGPath(roundedRect: scr, cornerWidth: rS, cornerHeight: rS, transform: nil)); ctx.clip()
    ctx.draw(loadImage(s.file), in: scr)
    // notch
    let nw = 0.505 * sw, nh = 0.0335 * S
    let notch = CGPath(roundedRect: CGRect(x: -nw / 2, y: S / 2 - nh, width: nw, height: 2 * nh),
                       cornerWidth: nh / 2, cornerHeight: nh / 2, transform: nil)
    fillPath(notch, color(bezel))
    // gloss
    let g0 = CGPoint(x: -sw / 2, y: S / 2), g1 = CGPoint(x: -sw / 2 + 0.45 * sw, y: S / 2 - 0.45 * S)
    ctx.drawLinearGradient(grad([(0xFFFFFF, 0.10, 0), (0xFFFFFF, 0, 1)]), start: g0, end: g1, options: [])
    if s.tier == 0 { ctx.setFillColor(color(tealDark, 0.22)); ctx.fill(scr) }
    ctx.restoreGState()
    ctx.restoreGState()
}

[BL4, BR4, BL3, BR3, BL2, BR2, BL1, BR1].forEach(phone)

// ---------------------------------------------------------------- 4. Mihrab
var arch: [CGPoint] = []
func cubic(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint, _ d: CGPoint, _ t: CGFloat) -> CGPoint {
    let u = 1 - t
    return CGPoint(x: u*u*u*a.x + 3*u*u*t*b.x + 3*u*t*t*c.x + t*t*t*d.x,
                   y: u*u*u*a.y + 3*u*u*t*b.y + 3*u*t*t*c.y + t*t*t*d.y)
}
do {
    for y in stride(from: CGFloat(1440), through: 560, by: -4) { arch.append(CGPoint(x: 860, y: y)) }
    for i in 1...120 { arch.append(cubic(CGPoint(x: 860, y: 560), CGPoint(x: 860, y: 470), CGPoint(x: 1140, y: 450), CGPoint(x: 1200, y: 420), CGFloat(i) / 120)) }
    for i in 1...120 { arch.append(cubic(CGPoint(x: 1200, y: 420), CGPoint(x: 1260, y: 450), CGPoint(x: 1540, y: 470), CGPoint(x: 1540, y: 560), CGFloat(i) / 120)) }
    for y in stride(from: CGFloat(564), through: 1440, by: 4) { arch.append(CGPoint(x: 1540, y: y)) }
}
let archPath = polyPoints(arch)
ctx.saveGState()
ctx.addPath(archPath); ctx.clip()
ctx.drawLinearGradient(grad([(tealDark, 1, 0), (0x062F34, 1, 1)]), start: P(0, 420), end: P(0, 1440), options: [])
for j in 0...(1100 / 60) { for i in 0...(800 / 60) {
    strokePath(khatam(830 + CGFloat(i) * 60, 400 + CGFloat(j) * 60, ro: 30), color(gold, 0.12), 1)
} }
// Shamseh
do {
    let cx: CGFloat = 1200, cy: CGFloat = 930
    for k in 0..<32 {
        let a = CGFloat(k) * 2 * .pi / 32 - .pi / 2
        let tipR: CGFloat = k % 2 == 0 ? 400 : 320
        let da = 5.06 * CGFloat.pi / 180
        let k0 = P(cx + 190 * cos(a - da), cy + 190 * sin(a - da))
        let k1 = P(cx + 190 * cos(a + da), cy + 190 * sin(a + da))
        let tip = P(cx + tipR * cos(a), cy + tipR * sin(a))
        let p = CGMutablePath(); p.move(to: k0); p.addLine(to: tip); p.addLine(to: k1); p.closeSubpath()
        fillGradient(p, grad([(0xF3D27A, 1, 0), (0xB8901F, 1, 1)]), from: P(cx + 190 * cos(a), cy + 190 * sin(a)), to: tip)
        strokePath(p, color(goldDeep), 1)
    }
    strokePath(circle(cx, cy, 190), color(gold), 4)
    for k in 0..<48 {
        let a = CGFloat(k) * 2 * .pi / 48
        fillPath(circle(cx + 176 * cos(a), cy + 176 * sin(a), 4), color(paper))
    }
    let disc = CGMutablePath()
    for i in 0...360 {
        let t = CGFloat(i) * .pi / 180, r = 170 * (0.94 + 0.06 * abs(cos(8 * t)))
        let q = P(cx + r * cos(t), cy + r * sin(t))
        if i == 0 { disc.move(to: q) } else { disc.addLine(to: q) }
    }
    disc.closeSubpath()
    fillPath(disc, color(teal)); strokePath(disc, color(goldLight, 0.7), 1.5)
    strokePath(star(cx, cy, n: 8, ro: 120, ri: 92), color(goldLight), 2)
    strokePath(star(cx, cy, n: 8, ro: 80, ri: 62, rot: .pi / 8), color(gold, 0.8), 1.5)
    fillPath(circle(cx, cy, 14), color(gold))
}
ctx.restoreGState()
// Frame
do {
    strokedFill(archPath, width: 30, gradient: grad([(goldShade, 1, 0), (goldShade, 1, 1)]), from: .zero, to: CGPoint(x: 0, y: 1))
    strokedFill(archPath, width: 24, gradient: goldGrad, from: P(0, 420), to: P(0, 1100))
    strokePath(archPath, color(goldLight), 3)
    pearls(along: arch, every: 22, r: 3, color: color(paper))
    // finial
    let fin = CGMutablePath()
    fin.move(to: P(1191, 408)); fin.addCurve(to: P(1200, 376), control1: P(1191, 394), control2: P(1198, 386))
    fin.addCurve(to: P(1209, 408), control1: P(1202, 386), control2: P(1209, 394)); fin.closeSubpath()
    fillGradient(fin, goldGrad, from: P(0, 376), to: P(0, 410)); strokePath(fin, color(goldDeep), 1)
    fillPath(circle(1200, 370, 4), color(goldLight))
    for x in [860, 1540] as [CGFloat] {
        let cap = rrect(x - 23, 552, x + 23, 568, 3)
        fillGradient(cap, goldGrad, from: P(0, 552), to: P(0, 568)); strokePath(cap, color(goldDeep), 1)
    }
}
phone(H)
[FL4, FR4, FL3, FR3, FL2, FR2, FL1, FR1].forEach(phone)

// Foreground sparkles
func fgSparkle(_ x0: CGFloat, _ x1: CGFloat, _ y0: CGFloat, _ y1: CGFloat, _ n: Int) {
    for _ in 0..<n {
        let x = x0 + rnd() * (x1 - x0), y = y0 + rnd() * (y1 - y0)
        let u = rnd(), r45 = rnd() < 0.5, al = 0.5 + 0.5 * rnd()
        sparkle(x, y, 4 + 10 * u * u, r45 ? .pi / 4 : 0, al)
    }
}
fgSparkle(60, 880, 250, 370, 4); fgSparkle(1520, 2340, 250, 370, 4)
fgSparkle(870, 1530, 385, 408, 4)
fgSparkle(60, 2340, 1440, 1470, 10)

// Chips & bottom text
do {
    let size: CGFloat = 22
    let items: [(String, Bool)] = [("۶۹۲ غزل حافظ", true), ("امتیاز · سطح · روز پیاپی", false),
                                   ("مرور فاصله\u{200C}دار", false), ("۴ شاعر آفلاین", false)]
    let paths = items.map { shape($0.0, vzSemi, size) }
    let widths: [CGFloat] = paths.enumerated().map { $0.element.boundingBoxOfPath.width + 56 + (items[$0.offset].1 ? 30 : 0) }
    let total = widths.reduce(0, +) + 18 * CGFloat(widths.count - 1)
    var right = 1200 + total / 2
    for (i, it) in items.enumerated() {
        let w = widths[i], left = right - w
        let chip = rrect(left, 1478, right, 1530, 26)
        ctx.saveGState(); ctx.setShadow(offset: CGSize(width: 0, height: -4), blur: 10, color: color(0x000000, 0.4))
        if it.1 { fillGradient(chip, grad([(0xE9C75A, 1, 0), (gold, 1, 1)]), from: P(left, 0), to: P(right, 0))
            fillPath(chip, color(gold, 0.01)) }
        else { fillPath(chip, color(tealDark)) }
        ctx.restoreGState()
        if it.1 { fillGradient(chip, grad([(0xE9C75A, 1, 0), (gold, 1, 1)]), from: P(left, 0), to: P(right, 0))
            strokePath(rrect(left + 1, 1479, right - 1, 1529, 25), color(goldDeep), 2)
        } else { strokePath(rrect(left + 1, 1479, right - 1, 1529, 25), color(gold), 2) }
        let p = paths[i], bb = p.boundingBoxOfPath
        let textCx = it.1 ? (left + right) / 2 - 12 : (left + right) / 2
        let tp = p.copy(using: [CGAffineTransform(translationX: textCx - bb.midX, y: Y(1504 + 8))])!
        fillPath(tp, color(it.1 ? ink : paper))
        if it.1 {
            let st = star(right - 28 - 9, 1504, n: 8, ro: 9, ri: 5.5)
            fillPath(st, color(ink)); 
        }
        right = left - 18
    }
    fillPath(uiText("Free & open-source · iOS", vzMed, size: 22, cx: 450, base: 1512), color(paper, 0.75))
    fillPath(uiText("رایگان و متن\u{200C}باز · iOS", vzMed, size: 22, cx: 1950, base: 1512), color(paper, 0.75))
}

// Vignette
ctx.drawRadialGradient(grad([(0x000000, 0, 0), (0x000000, 0, 900 / 1500), (0x000000, 0.35, 1)]),
                       startCenter: P(1200, 800), startRadius: 0, endCenter: P(1200, 800), endRadius: 1500,
                       options: [.drawsAfterEndLocation])

// Lachak corners
ctx.saveGState()
ctx.clip(to: CGRect(x: 56, y: Y(1544), width: 2288, height: 1488))
func lachak(_ ox: CGFloat, _ oy: CGFloat, _ sx: CGFloat, _ sy: CGFloat) {
    func pt(_ r: CGFloat, _ t: CGFloat) -> CGPoint { P(ox + sx * r * cos(t), oy + sy * r * sin(t)) }
    let p = CGMutablePath(); p.move(to: P(ox, oy))
    for i in 0...90 {
        let t = CGFloat(i) * .pi / 180
        p.addLine(to: pt(140 * (0.93 + 0.07 * abs(cos(6 * t))), t))
    }
    p.closeSubpath()
    ctx.saveGState(); ctx.addPath(p); ctx.clip()
    ctx.drawRadialGradient(grad([(gold, 0.30, 0), (goldDeep, 0.15, 1)]), startCenter: P(ox, oy), startRadius: 0,
                           endCenter: P(ox, oy), endRadius: 150, options: [.drawsAfterEndLocation])
    ctx.restoreGState()
    strokePath(p, color(gold), 2)
    let sc = CGMutablePath()
    for i in 0...90 {
        let t = CGFloat(i) * .pi / 180, r = 105 * (0.94 + 0.06 * abs(cos(6 * t)))
        if i == 0 { sc.move(to: pt(r, t)) } else { sc.addLine(to: pt(r, t)) }
    }
    strokePath(sc, color(goldLight), 1)
    for k in 0..<9 {
        let t = (CGFloat(k) * 11.25) * .pi / 180
        let c = pt(62, t)
        ctx.saveGState(); ctx.translateBy(x: c.x, y: c.y)
        ctx.rotate(by: atan2(sy * sin(t), sx * cos(t)))
        ctx.setFillColor(color(gold, 0.6))
        ctx.fillEllipse(in: CGRect(x: -17, y: -6, width: 34, height: 12))
        ctx.restoreGState()
    }
}
lachak(56, 56, 1, 1); lachak(2344, 56, -1, 1); lachak(56, 1544, 1, -1); lachak(2344, 1544, -1, -1)
ctx.restoreGState()

// ---------------------------------------------------------------- Border
func borderBand() {
    fillPath(CGPath(rect: CGRect(x: 0, y: 0, width: W, height: Hh), transform: nil), color(0x000000, 0))
    func ring(_ a: CGFloat, _ b: CGFloat, _ c: CGColor) {
        let p = CGMutablePath()
        p.addRect(CGRect(x: a, y: a, width: W - 2 * a, height: Hh - 2 * a))
        p.addRect(CGRect(x: b, y: b, width: W - 2 * b, height: Hh - 2 * b))
        ctx.addPath(p); ctx.setFillColor(c); ctx.fillPath(using: .evenOdd)
    }
    ring(0, 6, color(tealNight)); ring(6, 10, color(gold)); ring(10, 46, color(tealDark))
    ring(46, 50, color(gold)); ring(50, 56, color(paper, 0.55))
    // interlace: sides in spec space, centreline offset 28
    let L: CGFloat = 48, A: CGFloat = 9
    func side(_ start: CGPoint, _ end: CGPoint) {
        let len = hypot(end.x - start.x, end.y - start.y)
        let n = Int((len / L).rounded()), Ls = len / CGFloat(n)
        let dx = (end.x - start.x) / len, dy = (end.y - start.y) / len
        let nx = -dy, ny = dx
        func pos(_ s: CGFloat, _ off: CGFloat) -> CGPoint {
            CGPoint(x: start.x + dx * s + nx * off, y: start.y + dy * s + ny * off)
        }
        for k in 0..<(2 * n) {
            let s0 = CGFloat(k) * Ls / 2, s1 = CGFloat(k + 1) * Ls / 2
            func strand(_ sign: CGFloat) -> CGPath {
                let p = CGMutablePath()
                let steps = 24
                for i in 0...steps {
                    let s = s0 + (s1 - s0) * CGFloat(i) / CGFloat(steps)
                    let q = pos(s, sign * A * sin(2 * .pi * s / Ls))
                    let pp = P(q.x, q.y)
                    if i == 0 { p.move(to: pp) } else { p.addLine(to: pp) }
                }
                return p
            }
            let order: [CGFloat] = k % 2 == 0 ? [1, -1] : [-1, 1]
            for sg in order {
                let p = strand(sg)
                strokePath(p, color(tealNight), 6); strokePath(p, color(gold), 2.5)
            }
        }
        for m in 0..<(2 * n) {
            let sStar = Ls / 4 + CGFloat(m) * Ls / 2
            if sStar < len { let q = pos(sStar, 0); fillPath(star(q.x, q.y, n: 4, ro: 5, ri: 2), color(goldLight)) }
        }
        for m in 0...(2 * n) {
            let q = pos(CGFloat(m) * Ls / 2, 0); fillPath(circle(q.x, q.y, 2.5), color(paper))
        }
    }
    side(CGPoint(x: 56, y: 28), CGPoint(x: 2344, y: 28))
    side(CGPoint(x: 2344, y: 1572), CGPoint(x: 56, y: 1572))
    // vertical sides: perpendicular offset must point toward the band, so draw with explicit direction
    side(CGPoint(x: 28, y: 1544), CGPoint(x: 28, y: 56))
    side(CGPoint(x: 2372, y: 56), CGPoint(x: 2372, y: 1544))
    for (x, y) in [(0, 0), (2344, 0), (0, 1544), (2344, 1544)] as [(CGFloat, CGFloat)] {
        fillPath(rrect(x, y, x + 56, y + 56, 0), color(tealNight))
        strokePath(rrect(x + 3, y + 3, x + 53, y + 53, 0), color(gold, 0.5), 1)
        let s = star(x + 28, y + 28, n: 8, ro: 20, ri: 15.3)
        fillPath(s, color(gold)); strokePath(s, color(goldDeep), 1)
        fillPath(circle(x + 28, y + 28, 4), color(paper))
    }
}
borderBand()

// Debug
if debug {
    ctx.setStrokeColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1)); ctx.setLineWidth(2)
    for r in debugRects {
        ctx.saveGState(); ctx.translateBy(x: r.0, y: Y(r.1)); ctx.rotate(by: -r.4 * .pi / 180)
        ctx.stroke(CGRect(x: -r.2 / 2, y: -r.3 / 2, width: r.2, height: r.3)); ctx.restoreGState()
    }
    ctx.addPath(archPath); ctx.strokePath()
}

// ---------------------------------------------------------------- Output
let image = ctx.makeImage()!
func write(_ path: String, _ type: UTType, _ opts: [CFString: Any]?) {
    let d = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL, type.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(d, image, opts as CFDictionary?)
    guard CGImageDestinationFinalize(d) else { FileHandle.standardError.write(Data("failed \(path)\n".utf8)); exit(1) }
}
if debug {
    try? FileManager.default.createDirectory(atPath: "build", withIntermediateDirectories: true)
    write("build/poster-debug.png", .png, nil)
} else {
    write("docs/poster.png", .png, nil)
    // JPEG has no alpha: flatten onto opaque RGB
    let flat = CGContext(data: nil, width: Int(W), height: Int(Hh), bitsPerComponent: 8, bytesPerRow: 0, space: space,
                         bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    flat.draw(image, in: CGRect(x: 0, y: 0, width: W, height: Hh))
    let jd = CGImageDestinationCreateWithURL(URL(fileURLWithPath: "docs/poster.jpg") as CFURL, UTType.jpeg.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(jd, flat.makeImage()!, [kCGImageDestinationLossyCompressionQuality: 0.88] as CFDictionary)
    CGImageDestinationFinalize(jd)
}
print("done")

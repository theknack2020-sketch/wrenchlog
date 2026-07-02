// GenerateAppIcon.swift
// Standalone Swift script — run via: swift GenerateAppIcon.swift
// Generates 1024x1024 app icon PNGs using CoreGraphics.
//
// Output:
//   icon_1024.png        — amber-to-deep-orange gradient + white wrench-shield
//   icon_dark_1024.png   — dark background + light amber wrench-shield
//   icon_tinted_1024.png — single-color silhouette for iOS tinted variant

import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let size: CGFloat = 1024
let scale: CGFloat = 1

// MARK: - Color Helpers

struct RGBA {
    let r, g, b, a: CGFloat
    var cgColor: CGColor { CGColor(red: r, green: g, blue: b, alpha: a) }
}

let amberTop    = RGBA(r: 0.96, g: 0.68, b: 0.12, a: 1)  // bright amber
let amberBottom = RGBA(r: 0.82, g: 0.42, b: 0.04, a: 1)  // deep orange
let darkBg      = RGBA(r: 0.08, g: 0.08, b: 0.10, a: 1)
let lightAmber  = RGBA(r: 0.96, g: 0.78, b: 0.35, a: 1)
let white       = RGBA(r: 1.0,  g: 1.0,  b: 1.0,  a: 1)
let tintedGray  = RGBA(r: 0.55, g: 0.55, b: 0.58, a: 1)

// MARK: - PNG Writing

func writePNG(_ context: CGContext, to path: String) {
    guard let image = context.makeImage() else {
        print("ERROR: Failed to create image for \(path)")
        return
    }
    let url = URL(fileURLWithPath: path)
    guard let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else {
        print("ERROR: Cannot create destination at \(path)")
        return
    }
    CGImageDestinationAddImage(dest, image, nil)
    if CGImageDestinationFinalize(dest) {
        print("✅ Wrote \(path)")
    } else {
        print("ERROR: Failed to finalize \(path)")
    }
}

// MARK: - Gradient Fill

func fillGradient(_ ctx: CGContext, topColor: RGBA, bottomColor: RGBA) {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let colors = [topColor.cgColor, bottomColor.cgColor] as CFArray
    guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 1]) else { return }
    ctx.drawLinearGradient(gradient,
                           start: CGPoint(x: size / 2, y: 0),
                           end: CGPoint(x: size / 2, y: size),
                           options: [])
}

func fillSolid(_ ctx: CGContext, color: RGBA) {
    ctx.setFillColor(color.cgColor)
    ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))
}

// MARK: - Wrench + Shield Symbol Drawing

/// Draws a stylized wrench over a shield/gear-inspired hexagonal badge.
/// The design is bold, geometric, and recognizable at small sizes.
func drawSymbol(_ ctx: CGContext, color: RGBA, shadowOpacity: CGFloat = 0.18) {
    let cx = size / 2
    let cy = size / 2

    // --- Outer shield / badge shape (rounded hexagon-ish) ---
    let shieldSize: CGFloat = size * 0.44
    let shieldRect = CGRect(x: cx - shieldSize, y: cy - shieldSize,
                            width: shieldSize * 2, height: shieldSize * 2)

    // Drop shadow for depth
    if shadowOpacity > 0 {
        ctx.setShadow(offset: CGSize(width: 0, height: size * 0.012),
                      blur: size * 0.04,
                      color: CGColor(red: 0, green: 0, blue: 0, alpha: shadowOpacity))
    }

    // Shield body — rounded rect with pointed bottom
    ctx.saveGState()
    let shieldPath = CGMutablePath()
    let cornerRadius: CGFloat = shieldSize * 0.28
    let topY = shieldRect.minY
    let botY = shieldRect.maxY + shieldSize * 0.10  // extended bottom
    let leftX = shieldRect.minX
    let rightX = shieldRect.maxX

    shieldPath.move(to: CGPoint(x: cx, y: botY))  // bottom point
    shieldPath.addLine(to: CGPoint(x: leftX, y: cy + shieldSize * 0.20))
    shieldPath.addArc(tangent1End: CGPoint(x: leftX, y: topY),
                      tangent2End: CGPoint(x: cx, y: topY),
                      radius: cornerRadius)
    shieldPath.addArc(tangent1End: CGPoint(x: rightX, y: topY),
                      tangent2End: CGPoint(x: rightX, y: cy + shieldSize * 0.20),
                      radius: cornerRadius)
    shieldPath.addLine(to: CGPoint(x: rightX, y: cy + shieldSize * 0.20))
    shieldPath.closeSubpath()

    ctx.addPath(shieldPath)
    ctx.setFillColor(color.cgColor)
    ctx.fillPath()
    ctx.restoreGState()

    // Reset shadow for inner elements
    ctx.setShadow(offset: .zero, blur: 0, color: nil)

    // --- Wrench icon (bold, geometric) inside shield ---
    // Using a simplified wrench shape: handle + jaw
    let wrenchColor: CGColor
    if color.r > 0.9 && color.g > 0.9 && color.b > 0.9 {
        // White symbol → dark wrench interior
        wrenchColor = RGBA(r: 0.20, g: 0.15, b: 0.05, a: 0.22).cgColor
    } else {
        // Colored symbol → slightly lighter interior
        wrenchColor = RGBA(r: 1, g: 1, b: 1, a: 0.22).cgColor
    }

    // Wrench as a rotated thick shape
    ctx.saveGState()
    ctx.translateBy(x: cx, y: cy - shieldSize * 0.04)
    ctx.rotate(by: -0.65)  // ~37 degrees

    let handleW: CGFloat = shieldSize * 0.20
    let handleH: CGFloat = shieldSize * 0.95
    let jawW: CGFloat = shieldSize * 0.42
    let jawH: CGFloat = shieldSize * 0.26
    let handleR: CGFloat = handleW * 0.35

    // Handle
    let handleRect = CGRect(x: -handleW / 2, y: -handleH / 2,
                            width: handleW, height: handleH)
    let handlePath = CGPath(roundedRect: handleRect,
                            cornerWidth: handleR, cornerHeight: handleR,
                            transform: nil)
    ctx.addPath(handlePath)
    ctx.setFillColor(wrenchColor)
    ctx.fillPath()

    // Top jaw (open wrench head)
    let topJawRect = CGRect(x: -jawW / 2, y: -handleH / 2 - jawH * 0.2,
                            width: jawW, height: jawH)
    let jawR: CGFloat = jawH * 0.30
    let jawPath = CGPath(roundedRect: topJawRect,
                         cornerWidth: jawR, cornerHeight: jawR,
                         transform: nil)
    ctx.addPath(jawPath)
    ctx.fillPath()

    // Jaw notch (cutout at top center)
    let notchW: CGFloat = handleW * 0.55
    let notchH: CGFloat = jawH * 0.50
    let notchRect = CGRect(x: -notchW / 2,
                           y: -handleH / 2 - jawH * 0.2,
                           width: notchW, height: notchH)
    // "Cut" by filling with background-ish blend — we'll use clear blend mode
    ctx.saveGState()
    ctx.setBlendMode(.clear)
    ctx.fill(notchRect)
    ctx.restoreGState()

    // Bottom ring detail (closed end of wrench)
    let ringR: CGFloat = handleW * 0.48
    let ringCenter = CGPoint(x: 0, y: handleH / 2 - ringR * 0.3)
    ctx.addEllipse(in: CGRect(x: ringCenter.x - ringR,
                               y: ringCenter.y - ringR,
                               width: ringR * 2, height: ringR * 2))
    ctx.setFillColor(wrenchColor)
    ctx.fillPath()

    // Ring center hole
    let holeR: CGFloat = ringR * 0.40
    ctx.saveGState()
    ctx.setBlendMode(.clear)
    ctx.addEllipse(in: CGRect(x: ringCenter.x - holeR,
                               y: ringCenter.y - holeR,
                               width: holeR * 2, height: holeR * 2))
    ctx.fillPath()
    ctx.restoreGState()

    ctx.restoreGState()

    // --- Gear teeth around shield (subtle accents) ---
    let toothCount = 8
    let toothLength: CGFloat = shieldSize * 0.10
    let toothWidth: CGFloat = shieldSize * 0.12
    let toothRadius: CGFloat = shieldSize * 1.04

    ctx.saveGState()
    ctx.setFillColor(CGColor(red: color.r, green: color.g, blue: color.b, alpha: color.a * 0.35))

    for i in 0..<toothCount {
        let angle = (CGFloat(i) / CGFloat(toothCount)) * .pi * 2 - .pi / 2
        let tx = cx + cos(angle) * toothRadius
        let ty = cy + sin(angle) * toothRadius

        ctx.saveGState()
        ctx.translateBy(x: tx, y: ty)
        ctx.rotate(by: angle + .pi / 2)

        let toothRect = CGRect(x: -toothWidth / 2, y: -toothLength / 2,
                               width: toothWidth, height: toothLength)
        let toothPath = CGPath(roundedRect: toothRect,
                               cornerWidth: toothWidth * 0.25,
                               cornerHeight: toothWidth * 0.25,
                               transform: nil)
        ctx.addPath(toothPath)
        ctx.fillPath()
        ctx.restoreGState()
    }
    ctx.restoreGState()
}

// MARK: - Create Contexts & Generate

func makeContext() -> CGContext? {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    return CGContext(data: nil,
                    width: Int(size),
                    height: Int(size),
                    bitsPerComponent: 8,
                    bytesPerRow: 0,
                    space: colorSpace,
                    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
}

// Resolve output directory
let scriptPath = CommandLine.arguments[0]
let scriptDir = URL(fileURLWithPath: scriptPath).deletingLastPathComponent().path
let outputDir = scriptDir + "/Assets.xcassets/AppIcon.appiconset"

// Create output dir if needed
let fm = FileManager.default
try? fm.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

// --- 1. Default (amber gradient + white symbol) ---
if let ctx = makeContext() {
    fillGradient(ctx, topColor: amberTop, bottomColor: amberBottom)
    drawSymbol(ctx, color: white, shadowOpacity: 0.22)
    writePNG(ctx, to: outputDir + "/icon_1024.png")
}

// --- 2. Dark variant (dark bg + light amber symbol) ---
if let ctx = makeContext() {
    fillSolid(ctx, color: darkBg)
    drawSymbol(ctx, color: lightAmber, shadowOpacity: 0.30)
    writePNG(ctx, to: outputDir + "/icon_dark_1024.png")
}

// --- 3. Tinted variant (solid fill + single-color silhouette) ---
if let ctx = makeContext() {
    fillSolid(ctx, color: RGBA(r: 0.92, g: 0.92, b: 0.93, a: 1))  // very light gray bg
    drawSymbol(ctx, color: tintedGray, shadowOpacity: 0)
    writePNG(ctx, to: outputDir + "/icon_tinted_1024.png")
}

print("\n🎨 App icon generation complete.")

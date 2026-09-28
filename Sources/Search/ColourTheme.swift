import AppKit
import SwiftUI

/// A tint for Search's own surfaces, independent of the pages' light or dark look.
struct ColourTheme: Equatable {
    private let hex: String?
    static let neutral = ColourTheme(hex: nil)

    var rawValue: String { hex ?? "neutral" }
    var colour: Color { Color(nsColor: tint ?? NSColor(white: 0.55, alpha: 1)) }

    private init(hex: String?) { self.hex = hex }

    init?(rawValue: String) {
        if rawValue == "neutral" { self = .neutral; return }
        // Keep a colour chosen in the first local preview when its preset
        // gives way to the colour picker.
        let presets = ["sand": "#C29457", "sage": "#599C6E", "ocean": "#4D8CC7",
                       "lavender": "#9975C7", "rose": "#C2667A"]
        let value = presets[rawValue] ?? rawValue.uppercased()
        guard value.count == 7, value.first == "#",
              value.dropFirst().allSatisfy({ "0123456789ABCDEF".contains($0) }) else { return nil }
        hex = value
    }

    init?(colour: NSColor) {
        guard let rgb = colour.usingColorSpace(.sRGB) else { return nil }
        let components = [rgb.redComponent, rgb.greenComponent, rgb.blueComponent]
        guard components.allSatisfy({ $0.isFinite }) else { return nil }
        let bytes = components.map { Int((min(1, max(0, $0)) * 255).rounded()) }
        hex = String(format: "#%02X%02X%02X", bytes[0], bytes[1], bytes[2])
    }

    private var tint: NSColor? {
        guard let hex, let rgb = UInt32(hex.dropFirst(), radix: 16) else { return nil }
        return NSColor(srgbRed: CGFloat((rgb >> 16) & 255) / 255,
                       green: CGFloat((rgb >> 8) & 255) / 255,
                       blue: CGFloat(rgb & 255) / 255, alpha: 1)
    }

    /// Keep the existing hierarchy of resting, hovered and selected surfaces.
    /// Each colour captures this theme, so a new choice replaces SwiftUI's
    /// cached colour while still resolving itself when the Mac changes look.
    func surface(light: CGFloat, dark: CGFloat) -> NSColor {
        let tint = tint
        return NSColor(name: nil) { appearance in
            let dim = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            let base = NSColor(white: dim ? dark : light, alpha: 1)
            guard let tint else { return base }
            return base.blended(withFraction: dim ? 0.20 : 0.16, of: tint) ?? base
        }
    }
}

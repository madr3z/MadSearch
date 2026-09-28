import AppKit
import Observation
import XCTest
@testable import Search

@MainActor
final class ColourThemeTests: XCTestCase {
    private var savedTheme: Any?
    private var savedLook: Any?
    private var paletteTheme: ColourTheme = .neutral
    private var appearance: NSAppearance?

    override class func setUp() {
        setenv("SEARCH_PROBE", "colour-themes-\(getpid())", 1)
        super.setUp()
    }

    override func setUp() async throws {
        _ = NSApplication.shared
        NSApp.setActivationPolicy(.prohibited)
        savedTheme = Store.settings.object(forKey: "colour.theme")
        savedLook = Store.settings.object(forKey: "look")
        paletteTheme = Palette.colourTheme
        appearance = NSApp.appearance
    }

    override func tearDown() async throws {
        Store.settings.set(savedTheme, forKey: "colour.theme")
        Store.settings.set(savedLook, forKey: "look")
        Palette.colourTheme = paletteTheme
        NSApp.appearance = appearance
    }

    func testChoiceSurvivesNewPreferencesWithoutChangingLook() throws {
        Store.settings.set(Look.dark.rawValue, forKey: "look")
        let chosen = try XCTUnwrap(ColourTheme(rawValue: "#12AB34"))
        let prefs = Preferences()
        prefs.colourTheme = chosen

        let restored = Preferences()
        XCTAssertEqual(restored.colourTheme, chosen)
        XCTAssertEqual(Palette.colourTheme, chosen)
        XCTAssertEqual(restored.look, .dark)
        XCTAssertEqual(NSApp.appearance?.name, .darkAqua)
        XCTAssertEqual(Store.settings.string(forKey: "colour.theme"), "#12AB34")
    }

    func testMissingOrUnknownThemeUsesOriginalPalette() throws {
        for stored in [nil, "a-theme-from-a-newer-version", "#GGGGGG", "#123", "#12345678"] as [String?] {
            Store.settings.set(stored, forKey: "colour.theme")
            XCTAssertEqual(Preferences().colourTheme, .neutral)
            for (name, white) in [(NSAppearance.Name.aqua, 1.0), (.darkAqua, 0.11)] {
                let look = try XCTUnwrap(NSAppearance(named: name))
                XCTAssertEqual(try resolved(Palette.NS.ground, look),
                               try resolved(NSColor(white: white, alpha: 1), look))
            }
        }
    }

    func testPaletteReadersObserveSelectionAndReceiveNewColours() throws {
        Palette.colourTheme = .neutral
        let previous = Palette.NS.ground
        let redraw = expectation(description: "a view reading the palette is invalidated")
        withObservationTracking {
            _ = Palette.ground
            _ = Palette.wash
        } onChange: {
            redraw.fulfill()
        }
        Palette.colourTheme = try XCTUnwrap(ColourTheme(rawValue: "#0088AA"))
        wait(for: [redraw], timeout: 1)

        for name in [NSAppearance.Name.aqua, .darkAqua] {
            let look = try XCTUnwrap(NSAppearance(named: name))
            XCTAssertNotEqual(try resolved(previous, look), try resolved(Palette.NS.ground, look))
        }
    }

    func testTextStaysLegibleOnThemedSurfacesInBothLooks() throws {
        let colours = ["neutral", "#000000", "#FFFFFF", "#FF0000", "#00FF00", "#0000FF",
                       "#FFFF00", "#FF00FF", "#00FFFF", "#12AB34", "#8765AB"]
        for colour in colours {
            let theme = try XCTUnwrap(ColourTheme(rawValue: colour))
            Palette.colourTheme = theme
            for name in [NSAppearance.Name.aqua, .darkAqua] {
                let look = try XCTUnwrap(NSAppearance(named: name))
                for surface in [Palette.NS.ground, Palette.NS.wash, Palette.NS.hover, Palette.NS.pinLive] {
                    XCTAssertGreaterThanOrEqual(try contrast(Palette.NS.ink, surface, look), 4.5,
                                                "\(colour) in \(name.rawValue)")
                    if theme != .neutral {
                        XCTAssertGreaterThanOrEqual(try contrast(Palette.NS.muted, surface, look), 3,
                                                    "\(colour)'s secondary text in \(name.rawValue)")
                    }
                }
            }
        }
    }

    func testPickerColoursAreSavedAsOpaqueSRGBAndOldChoicesAreKept() throws {
        let chosen = try XCTUnwrap(ColourTheme(colour: NSColor(srgbRed: 1, green: 0, blue: 0.5, alpha: 0.25)))
        XCTAssertEqual(chosen.rawValue, "#FF0080")
        let restored = try XCTUnwrap(ColourTheme(rawValue: chosen.rawValue))
        XCTAssertEqual(restored, chosen)
        let rgb = try XCTUnwrap(NSColor(restored.colour).usingColorSpace(.sRGB))
        XCTAssertEqual(rgb.alphaComponent, 1)
        XCTAssertEqual(ColourTheme(rawValue: "#1a2b3c")?.rawValue, "#1A2B3C")
        XCTAssertEqual(ColourTheme(rawValue: "ocean"), ColourTheme(rawValue: "#4D8CC7"))
    }

    private func contrast(_ ink: NSColor, _ ground: NSColor, _ look: NSAppearance) throws -> Double {
        func luminance(_ colour: NSColor) throws -> Double {
            let rgb = try resolved(colour, look)
            func linear(_ component: CGFloat) -> Double {
                let value = Double(component)
                return value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
            }
            return 0.2126 * linear(rgb.redComponent) + 0.7152 * linear(rgb.greenComponent)
                + 0.0722 * linear(rgb.blueComponent)
        }
        let a = try luminance(ink), b = try luminance(ground)
        return (max(a, b) + 0.05) / (min(a, b) + 0.05)
    }

    private func resolved(_ colour: NSColor, _ look: NSAppearance) throws -> NSColor {
        var rgb: NSColor?
        look.performAsCurrentDrawingAppearance { rgb = colour.usingColorSpace(.sRGB) }
        return try XCTUnwrap(rgb)
    }
}

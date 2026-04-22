import Testing
import CoreGraphics
@testable import Vantage

@Suite("WindowManagerModel")
struct WindowManagerTests {
    let screen = CGRect(x: 0, y: 23, width: 1440, height: 877) // typical AX screen

    @Test("leftHalf fills left 50% of screen")
    func leftHalf() {
        let zone = SnapZone.all.first(where: { $0.id == "leftHalf" })!
        let f = zone.axFrame(in: screen)
        #expect(f.origin.x == screen.origin.x)
        #expect(f.width == screen.width / 2)
        #expect(f.height == screen.height)
    }

    @Test("rightHalf starts at screen midpoint")
    func rightHalf() {
        let zone = SnapZone.all.first(where: { $0.id == "rightHalf" })!
        let f = zone.axFrame(in: screen)
        #expect(f.origin.x == screen.origin.x + screen.width / 2)
        #expect(f.width == screen.width / 2)
    }

    @Test("fullscreen equals entire screen")
    func fullscreen() {
        let zone = SnapZone.all.first(where: { $0.id == "fullscreen" })!
        let f = zone.axFrame(in: screen)
        #expect(f == screen)
    }

    @Test("thirds sum to full width")
    func thirdsSum() {
        let left = SnapZone.all.first(where: { $0.id == "leftThird" })!.axFrame(in: screen)
        let center = SnapZone.all.first(where: { $0.id == "centerThird" })!.axFrame(in: screen)
        let right = SnapZone.all.first(where: { $0.id == "rightThird" })!.axFrame(in: screen)
        #expect(abs((left.width + center.width + right.width) - screen.width) < 1)
    }

    @Test("quarters sum to full area")
    func quartersArea() {
        let ids = ["topLeft", "topRight", "bottomLeft", "bottomRight"]
        let totalArea = ids.compactMap { id in
            SnapZone.all.first(where: { $0.id == id })?.axFrame(in: screen)
        }.reduce(0) { $0 + $1.width * $1.height }
        #expect(abs(totalArea - screen.width * screen.height) < 1)
    }

    @Test("all zones have unique IDs")
    func uniqueIDs() {
        let ids = SnapZone.all.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test("all zones have 15 entries")
    func zoneCount() {
        #expect(SnapZone.all.count == 15)
    }
}

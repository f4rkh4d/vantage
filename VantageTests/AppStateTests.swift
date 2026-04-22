import Testing
import SwiftUI
@testable import Vantage

@Suite("AppState")
@MainActor
struct AppStateTests {
    @Test("default active module is windowManager")
    func defaultModule() {
        let state = AppState()
        #expect(state.activeModule == .windowManager)
    }

    @Test("switching module updates activeModule")
    func switchModule() {
        let state = AppState()
        state.activeModule = .clipboard
        #expect(state.activeModule == .clipboard)
    }

    @Test("Module enum has 10 cases")
    func moduleCount() {
        #expect(Module.allCases.count == 10)
    }

    @Test("all modules have non-empty title and icon")
    func moduleMetadata() {
        for module in Module.allCases {
            #expect(!module.title.isEmpty)
            #expect(!module.icon.isEmpty)
        }
    }

    @Test("all module accent color RGB components are unique across modules")
    func moduleAccentColors() {
        let keys = Module.allCases.map { m -> String in
            let c = m.accentColor.resolve(in: EnvironmentValues())
            return String(format: "%.2f,%.2f,%.2f", c.red, c.green, c.blue)
        }
        #expect(Set(keys).count == Module.allCases.count)
    }
}

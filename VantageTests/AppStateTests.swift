import Testing
@testable import Vantage

@Suite("AppState")
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
}

import Testing
@testable import Vantage

@Suite("Setup")
struct SetupTests {
    @Test("project compiles")
    func projectCompiles() {
        #expect(true)
    }
}

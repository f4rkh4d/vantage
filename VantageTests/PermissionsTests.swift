import Testing
@testable import Vantage

@Suite("Permissions")
struct PermissionsTests {
    @Test("accessibility check returns Bool without crashing")
    func accessibilityCheck() {
        let result = Permissions.isAccessibilityGranted()
        #expect(result == true || result == false)
    }
}

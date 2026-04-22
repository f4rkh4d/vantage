import Testing
@testable import Vantage

@Suite("StatusPoller")
struct StatusPollerTests {
    @Test("cpu usage is between 0 and 1")
    func cpuRange() throws {
        let usage = try StatusPoller.currentCPUUsage()
        #expect(usage >= 0 && usage <= 1)
    }

    @Test("ram usage is between 0 and 1")
    func ramRange() throws {
        let usage = try StatusPoller.currentRAMUsage()
        #expect(usage >= 0 && usage <= 1)
    }

    @Test("battery level is between 0 and 1")
    func batteryRange() {
        let level = StatusPoller.currentBatteryLevel()
        #expect(level >= 0 && level <= 1)
    }
}

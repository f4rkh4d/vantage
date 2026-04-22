import Foundation
import IOKit.ps

@MainActor
final class BatteryPowerManager: ObservableObject {
    static let shared = BatteryPowerManager()
    private init() {}

    @Published var level: Double = 0
    @Published var isCharging: Bool = false
    @Published var isPluggedIn: Bool = false
    @Published var timeToEmpty: TimeInterval? = nil
    @Published var timeToFull: TimeInterval? = nil
    @Published var cycleCount: Int = 0
    @Published var health: Double = 1.0
    @Published var currentCapacityMAh: Int = 0
    @Published var designCapacityMAh: Int = 0
    @Published var temperature: Double = 0
    @Published var powerSource: String = "Battery"

    private var timer: Timer?

    func start() {
        poll()
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.poll() }
        }
    }

    func stop() { timer?.invalidate(); timer = nil }

    private func poll() {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let list = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as! [CFTypeRef]
        guard let ps = list.first,
              let info = IOPSGetPowerSourceDescription(snapshot, ps).takeUnretainedValue() as? [String: Any]
        else { return }

        level = (info[kIOPSCurrentCapacityKey] as? Double ?? 0) / 100.0
        isCharging = info[kIOPSIsChargingKey] as? Bool ?? false
        isPluggedIn = (info[kIOPSPowerSourceStateKey] as? String) == kIOPSACPowerValue
        powerSource = isPluggedIn ? "AC Power" : "Battery"

        if let tte = info[kIOPSTimeToEmptyKey] as? Int, tte > 0 {
            timeToEmpty = TimeInterval(tte * 60)
        } else {
            timeToEmpty = nil
        }
        if let ttf = info[kIOPSTimeToFullChargeKey] as? Int, ttf > 0 {
            timeToFull = TimeInterval(ttf * 60)
        } else {
            timeToFull = nil
        }

        let matching = IOServiceMatching("AppleSmartBattery") as! NSMutableDictionary
        let service = IOServiceGetMatchingService(kIOMainPortDefault, matching)
        if service != IO_OBJECT_NULL {
            func prop<T>(_ key: String) -> T? {
                IORegistryEntryCreateCFProperty(service, key as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? T
            }
            cycleCount = prop("CycleCount") ?? 0
            let cur: Int = prop("AppleRawCurrentCapacity") ?? 0
            let des: Int = prop("DesignCapacity") ?? 0
            currentCapacityMAh = cur
            designCapacityMAh = des
            health = des > 0 ? min(1.0, Double(cur) / Double(des)) : 1.0
            let tempRaw: Int = prop("Temperature") ?? 0
            temperature = Double(tempRaw) / 100.0
            IOObjectRelease(service)
        }
    }
}

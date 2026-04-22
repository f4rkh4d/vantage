import Foundation
import IOKit.ps

enum StatusPollerError: Error {
    case hostStatsFailed
}

struct StatusPoller {
    static func currentCPUUsage() throws -> Double {
        var cpuInfo: processor_info_array_t?
        var numCPUInfo: mach_msg_type_number_t = 0
        var numCPUs: natural_t = 0

        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &numCPUs,
            &cpuInfo,
            &numCPUInfo
        )
        guard result == KERN_SUCCESS, let info = cpuInfo else {
            throw StatusPollerError.hostStatsFailed
        }

        var totalUsed: Int32 = 0
        var totalAll: Int32 = 0
        for i in 0..<Int(numCPUs) {
            let base = Int32(CPU_STATE_MAX) * Int32(i)
            totalUsed += info[Int(base + Int32(CPU_STATE_USER))]
            totalUsed += info[Int(base + Int32(CPU_STATE_SYSTEM))]
            totalUsed += info[Int(base + Int32(CPU_STATE_NICE))]
            totalAll  += info[Int(base + Int32(CPU_STATE_USER))]
            totalAll  += info[Int(base + Int32(CPU_STATE_SYSTEM))]
            totalAll  += info[Int(base + Int32(CPU_STATE_NICE))]
            totalAll  += info[Int(base + Int32(CPU_STATE_IDLE))]
        }
        vm_deallocate(
            mach_task_self_,
            vm_address_t(bitPattern: info),
            vm_size_t(numCPUInfo) * vm_size_t(MemoryLayout<Int32>.size)
        )
        guard totalAll > 0 else { return 0 }
        return Double(totalUsed) / Double(totalAll)
    }

    static func currentRAMUsage() throws -> Double {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size
        )
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { throw StatusPollerError.hostStatsFailed }
        let pageSize = Double(vm_kernel_page_size)
        let used = Double(stats.active_count + stats.wire_count) * pageSize
        let total = Double(ProcessInfo.processInfo.physicalMemory)
        return min(used / total, 1.0)
    }

    static func currentBatteryLevel() -> Double {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as [CFTypeRef]
        for source in sources {
            if let desc = IOPSGetPowerSourceDescription(snapshot, source)
                .takeUnretainedValue() as? [String: Any],
               let capacity = desc[kIOPSCurrentCapacityKey] as? Int,
               let max = desc[kIOPSMaxCapacityKey] as? Int,
               max > 0 {
                return Double(capacity) / Double(max)
            }
        }
        return 1.0 // desktop Mac — no battery
    }

    static func isCharging() -> Bool {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as [CFTypeRef]
        for source in sources {
            if let desc = IOPSGetPowerSourceDescription(snapshot, source)
                .takeUnretainedValue() as? [String: Any],
               let state = desc[kIOPSPowerSourceStateKey] as? String {
                return state == kIOPSACPowerValue
            }
        }
        return true // desktop Mac — always "charging"
    }

    /// Starts a repeating 2s timer that pushes fresh values to AppState on the main actor.
    /// Returns the timer so the caller can invalidate it on app termination.
    @MainActor
    static func startPolling(appState: AppState) -> Timer {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            Task { @MainActor in
                if let cpu = try? Self.currentCPUUsage() { appState.cpuUsage = cpu }
                if let ram = try? Self.currentRAMUsage() { appState.ramUsage = ram }
                appState.batteryLevel = Self.currentBatteryLevel()
                appState.isCharging = Self.isCharging()
            }
        }
    }
}

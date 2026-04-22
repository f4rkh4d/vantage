# Vantage — Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Xcode project skeleton for Vantage — menubar icon, popover with sidebar navigation, AppState, module routing, settings window, status bar, and permissions prompt. No module logic yet — just the shell that all 10 modules will plug into.

**Architecture:** Single NSStatusItem triggers an NSPopover (400×520pt). Inside: a 60pt icon sidebar + 340pt content area that SwiftUI switches based on `AppState.activeModule`. A 36pt status bar at the bottom always shows CPU/RAM/battery. Each of the 10 modules is a placeholder `View` for now.

**Tech Stack:** Swift 5.10+, SwiftUI, macOS 14+, Xcode 15+. SPM dependencies: [Sparkle](https://github.com/sparkle-project/Sparkle) (auto-update), [GRDB.swift](https://github.com/groue/GRDB.swift) (SQLite for clipboard — added in clipboard plan). No other dependencies for this plan.

---

## File Map

| File | Responsibility |
|------|---------------|
| `Vantage/App/VantageApp.swift` | `@main` entry point, wires AppDelegate |
| `Vantage/App/AppDelegate.swift` | NSStatusItem, NSPopover lifecycle |
| `Vantage/App/AppState.swift` | `@Observable` shared state, Module enum |
| `Vantage/App/MenubarView.swift` | Popover root: sidebar + content + status bar |
| `Vantage/App/SidebarView.swift` | Icon-only vertical nav, gear at bottom |
| `Vantage/App/ModuleContentView.swift` | Switches on `appState.activeModule` |
| `Vantage/App/StatusBarView.swift` | Bottom CPU/RAM/battery strip |
| `Vantage/App/SettingsView.swift` | Settings window root (tabbed per module) |
| `Vantage/Shared/Permissions.swift` | Check + request Accessibility access |
| `Vantage/Shared/StatusPoller.swift` | Timer-based CPU/RAM/battery polling |
| `Vantage/Modules/*/PlaceholderView.swift` | One file per module, "Coming soon" view |
| `VantageTests/AppStateTests.swift` | Unit tests for AppState |
| `VantageTests/StatusPollerTests.swift` | Unit tests for StatusPoller |

---

## Task 1: Create Xcode Project

**Files:**
- Create: `Vantage.xcodeproj` (via Xcode GUI)
- Create: `.gitignore`
- Create: `Vantage/App/VantageApp.swift`

- [ ] **Step 1: Open Xcode → File → New → Project**

  Select: **macOS → App**
  - Product Name: `Vantage`
  - Bundle Identifier: `com.yourname.vantage` (replace `yourname`)
  - Interface: **SwiftUI**
  - Language: **Swift**
  - Minimum deployment: **macOS 14.0**
  - Uncheck "Create Git repository" (we'll do it manually)
  - Save to: `/Users/bennett/Projects/menubar-app/`

- [ ] **Step 2: Configure Info.plist — hide from Dock**

  In Xcode: select the `Vantage` target → Info tab → add key:
  - Key: `Application is agent (UIElement)` → Value: `YES`

  Or directly in `Vantage/Info.plist`:
  ```xml
  <key>LSUIElement</key>
  <true/>
  ```

- [ ] **Step 3: Create Accessibility entitlement**

  In Xcode: select target → Signing & Capabilities → + Capability → **Hardened Runtime**

  Then open `Vantage.entitlements` (auto-created) and add:
  ```xml
  <key>com.apple.security.temporary-exception.apple-events</key>
  <true/>
  ```

  Also create `Vantage/Vantage.entitlements` if it doesn't exist:
  ```xml
  <?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
  <plist version="1.0">
  <dict>
      <key>com.apple.security.automation.apple-events</key>
      <true/>
  </dict>
  </plist>
  ```

- [ ] **Step 4: Add .gitignore and init git**

  ```bash
  cd /Users/bennett/Projects/menubar-app
  cat > .gitignore << 'EOF'
  .DS_Store
  *.xcuserstate
  xcuserdata/
  DerivedData/
  .build/
  .superpowers/
  *.ipa
  EOF
  git init
  git add .
  git commit -m "chore: init Xcode project for Vantage"
  ```

---

## Task 2: Add Sparkle via SPM

**Files:**
- Modify: `Vantage.xcodeproj/project.pbxproj` (via Xcode UI)

- [ ] **Step 1: Add Sparkle package**

  Xcode → File → Add Package Dependencies:
  - URL: `https://github.com/sparkle-project/Sparkle`
  - Version: Up to Next Major from `2.0.0`
  - Add to target: `Vantage`

- [ ] **Step 2: Verify build succeeds**

  ```bash
  cd /Users/bennett/Projects/menubar-app
  xcodebuild -scheme Vantage -configuration Debug build 2>&1 | tail -5
  ```
  Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

  ```bash
  git add .
  git commit -m "chore: add Sparkle for auto-update"
  ```

---

## Task 3: AppState and Module enum

**Files:**
- Create: `Vantage/App/AppState.swift`
- Create: `VantageTests/AppStateTests.swift`

- [ ] **Step 1: Write the failing test**

  Create `VantageTests/AppStateTests.swift`:
  ```swift
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
  ```

- [ ] **Step 2: Run to verify failure**

  ```bash
  xcodebuild test -scheme Vantage -destination 'platform=macOS' 2>&1 | grep -E "(FAILED|error:|AppState)"
  ```
  Expected: compile error — `AppState` not defined yet.

- [ ] **Step 3: Implement AppState.swift**

  Create `Vantage/App/AppState.swift`:
  ```swift
  import SwiftUI

  enum Module: String, CaseIterable, Identifiable {
      case windowManager
      case clipboard
      case systemMonitor
      case appLauncher
      case focus
      case displayControls
      case textSnippets
      case aiAssistant
      case networkTools
      case battery

      var id: String { rawValue }

      var title: String {
          switch self {
          case .windowManager:   return "Window Manager"
          case .clipboard:       return "Clipboard"
          case .systemMonitor:   return "System Monitor"
          case .appLauncher:     return "App Launcher"
          case .focus:           return "Focus"
          case .displayControls: return "Display Controls"
          case .textSnippets:    return "Text Snippets"
          case .aiAssistant:     return "AI Assistant"
          case .networkTools:    return "Network Tools"
          case .battery:         return "Battery & Power"
          }
      }

      var icon: String {
          switch self {
          case .windowManager:   return "rectangle.split.2x2"
          case .clipboard:       return "doc.on.clipboard"
          case .systemMonitor:   return "chart.bar.xaxis"
          case .appLauncher:     return "magnifyingglass"
          case .focus:           return "timer"
          case .displayControls: return "display"
          case .textSnippets:    return "text.cursor"
          case .aiAssistant:     return "sparkles"
          case .networkTools:    return "network"
          case .battery:         return "battery.75percent"
          }
      }
  }

  @Observable
  final class AppState {
      var activeModule: Module = .windowManager
      var cpuUsage: Double = 0        // 0.0–1.0
      var ramUsage: Double = 0        // 0.0–1.0
      var batteryLevel: Double = 1.0  // 0.0–1.0
      var isCharging: Bool = false
  }
  ```

- [ ] **Step 4: Run tests — expect pass**

  ```bash
  xcodebuild test -scheme Vantage -destination 'platform=macOS' 2>&1 | grep -E "(passed|failed|AppState)"
  ```
  Expected: `Test Suite 'AppStateTests' passed`

- [ ] **Step 5: Commit**

  ```bash
  git add Vantage/App/AppState.swift VantageTests/AppStateTests.swift
  git commit -m "feat: add AppState and Module enum"
  ```

---

## Task 4: StatusPoller — CPU, RAM, battery

**Files:**
- Create: `Vantage/Shared/StatusPoller.swift`
- Create: `VantageTests/StatusPollerTests.swift`

- [ ] **Step 1: Write the failing test**

  Create `VantageTests/StatusPollerTests.swift`:
  ```swift
  import Testing
  @testable import Vantage

  @Suite("StatusPoller")
  struct StatusPollerTests {
      @Test("cpu usage is between 0 and 1")
      func cpuRange() async throws {
          let usage = try StatusPoller.currentCPUUsage()
          #expect(usage >= 0 && usage <= 1)
      }

      @Test("ram usage is between 0 and 1")
      func ramRange() async throws {
          let usage = try StatusPoller.currentRAMUsage()
          #expect(usage >= 0 && usage <= 1)
      }

      @Test("battery level is between 0 and 1")
      func batteryRange() {
          let level = StatusPoller.currentBatteryLevel()
          #expect(level >= 0 && level <= 1)
      }
  }
  ```

- [ ] **Step 2: Run to verify failure**

  ```bash
  xcodebuild test -scheme Vantage -destination 'platform=macOS' 2>&1 | grep -E "(error:|StatusPoller)"
  ```
  Expected: compile error — `StatusPoller` not defined.

- [ ] **Step 3: Implement StatusPoller.swift**

  Create `Vantage/Shared/StatusPoller.swift`:
  ```swift
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
          vm_deallocate(mach_task_self_, vm_address_t(bitPattern: info), vm_size_t(numCPUInfo) * vm_size_t(MemoryLayout<Int32>.size))
          guard totalAll > 0 else { return 0 }
          return Double(totalUsed) / Double(totalAll)
      }

      static func currentRAMUsage() throws -> Double {
          var stats = vm_statistics64()
          var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
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
              if let desc = IOPSGetPowerSourceDescription(snapshot, source).takeUnretainedValue() as? [String: Any],
                 let capacity = desc[kIOPSCurrentCapacityKey] as? Int,
                 let max = desc[kIOPSMaxCapacityKey] as? Int,
                 max > 0 {
                  return Double(capacity) / Double(max)
              }
          }
          return 1.0 // no battery (desktop Mac)
      }

      /// Call this to start periodic polling. Updates appState on main actor.
      @MainActor
      static func startPolling(appState: AppState) -> Timer {
          return Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
              Task { @MainActor in
                  if let cpu = try? currentCPUUsage() { appState.cpuUsage = cpu }
                  if let ram = try? currentRAMUsage() { appState.ramUsage = ram }
                  appState.batteryLevel = currentBatteryLevel()
              }
          }
      }
  }
  ```

- [ ] **Step 4: Run tests — expect pass**

  ```bash
  xcodebuild test -scheme Vantage -destination 'platform=macOS' 2>&1 | grep -E "(passed|failed|StatusPoller)"
  ```
  Expected: `Test Suite 'StatusPollerTests' passed`

- [ ] **Step 5: Commit**

  ```bash
  git add Vantage/Shared/StatusPoller.swift VantageTests/StatusPollerTests.swift
  git commit -m "feat: add StatusPoller for CPU/RAM/battery"
  ```

---

## Task 5: Permissions helper

**Files:**
- Create: `Vantage/Shared/Permissions.swift`
- Create: `VantageTests/PermissionsTests.swift`

- [ ] **Step 1: Write the failing test**

  Create `VantageTests/PermissionsTests.swift`:
  ```swift
  import Testing
  @testable import Vantage

  @Suite("Permissions")
  struct PermissionsTests {
      @Test("accessibility check returns a Bool without crashing")
      func accessibilityCheck() {
          let result = Permissions.isAccessibilityGranted()
          // result will be false in test runner, but should not crash
          #expect(result == true || result == false)
      }
  }
  ```

- [ ] **Step 2: Run to verify failure**

  ```bash
  xcodebuild test -scheme Vantage -destination 'platform=macOS' 2>&1 | grep -E "(error:|Permissions)"
  ```
  Expected: compile error.

- [ ] **Step 3: Implement Permissions.swift**

  Create `Vantage/Shared/Permissions.swift`:
  ```swift
  import AppKit
  import ApplicationServices

  enum Permissions {
      static func isAccessibilityGranted() -> Bool {
          AXIsProcessTrusted()
      }

      /// Shows the system accessibility dialog if not granted.
      static func requestAccessibilityIfNeeded() {
          guard !isAccessibilityGranted() else { return }
          let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
          AXIsProcessTrustedWithOptions(options)
      }
  }
  ```

- [ ] **Step 4: Run tests**

  ```bash
  xcodebuild test -scheme Vantage -destination 'platform=macOS' 2>&1 | grep -E "(passed|failed|Permissions)"
  ```
  Expected: `Test Suite 'PermissionsTests' passed`

- [ ] **Step 5: Commit**

  ```bash
  git add Vantage/Shared/Permissions.swift VantageTests/PermissionsTests.swift
  git commit -m "feat: add Permissions helper for AX access"
  ```

---

## Task 6: Placeholder views for all 10 modules

**Files:**
- Create: `Vantage/Modules/WindowManager/WindowManagerView.swift`
- Create: `Vantage/Modules/Clipboard/ClipboardView.swift`
- Create: `Vantage/Modules/SystemMonitor/SystemMonitorView.swift`
- Create: `Vantage/Modules/AppLauncher/AppLauncherView.swift`
- Create: `Vantage/Modules/Focus/FocusView.swift`
- Create: `Vantage/Modules/DisplayControls/DisplayControlsView.swift`
- Create: `Vantage/Modules/TextSnippets/TextSnippetsView.swift`
- Create: `Vantage/Modules/AIAssistant/AIAssistantView.swift`
- Create: `Vantage/Modules/NetworkTools/NetworkToolsView.swift`
- Create: `Vantage/Modules/Battery/BatteryView.swift`

- [ ] **Step 1: Create folder structure in Xcode**

  In Xcode's Project Navigator: right-click `Vantage` group → New Group without folder for each module path, or just create the files — Xcode will create groups automatically.

- [ ] **Step 2: Create all 10 placeholder views**

  Each file follows the same pattern. Create each file below:

  **`Vantage/Modules/WindowManager/WindowManagerView.swift`:**
  ```swift
  import SwiftUI

  struct WindowManagerView: View {
      var body: some View {
          VStack(spacing: 8) {
              Image(systemName: "rectangle.split.2x2")
                  .font(.system(size: 32))
                  .foregroundStyle(.secondary)
              Text("Window Manager")
                  .font(.headline)
              Text("Coming soon")
                  .font(.caption)
                  .foregroundStyle(.tertiary)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
  }
  ```

  Repeat this pattern for the remaining 9 modules, changing the `systemName`, `Text("...")` title, and struct name:

  | File | Struct | systemName |
  |------|--------|------------|
  | `Clipboard/ClipboardView.swift` | `ClipboardView` | `doc.on.clipboard` |
  | `SystemMonitor/SystemMonitorView.swift` | `SystemMonitorView` | `chart.bar.xaxis` |
  | `AppLauncher/AppLauncherView.swift` | `AppLauncherView` | `magnifyingglass` |
  | `Focus/FocusView.swift` | `FocusView` | `timer` |
  | `DisplayControls/DisplayControlsView.swift` | `DisplayControlsView` | `display` |
  | `TextSnippets/TextSnippetsView.swift` | `TextSnippetsView` | `text.cursor` |
  | `AIAssistant/AIAssistantView.swift` | `AIAssistantView` | `sparkles` |
  | `NetworkTools/NetworkToolsView.swift` | `NetworkToolsView` | `network` |
  | `Battery/BatteryView.swift` | `BatteryView` | `battery.75percent` |

- [ ] **Step 3: Build to verify no compile errors**

  ```bash
  xcodebuild -scheme Vantage -configuration Debug build 2>&1 | tail -3
  ```
  Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

  ```bash
  git add Vantage/Modules/
  git commit -m "feat: add placeholder views for all 10 modules"
  ```

---

## Task 7: ModuleContentView — routing

**Files:**
- Create: `Vantage/App/ModuleContentView.swift`

- [ ] **Step 1: Create ModuleContentView.swift**

  ```swift
  import SwiftUI

  struct ModuleContentView: View {
      @Environment(AppState.self) private var appState

      var body: some View {
          Group {
              switch appState.activeModule {
              case .windowManager:   WindowManagerView()
              case .clipboard:       ClipboardView()
              case .systemMonitor:   SystemMonitorView()
              case .appLauncher:     AppLauncherView()
              case .focus:           FocusView()
              case .displayControls: DisplayControlsView()
              case .textSnippets:    TextSnippetsView()
              case .aiAssistant:     AIAssistantView()
              case .networkTools:    NetworkToolsView()
              case .battery:         BatteryView()
              }
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
  }
  ```

- [ ] **Step 2: Build**

  ```bash
  xcodebuild -scheme Vantage -configuration Debug build 2>&1 | tail -3
  ```
  Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

  ```bash
  git add Vantage/App/ModuleContentView.swift
  git commit -m "feat: add ModuleContentView routing"
  ```

---

## Task 8: SidebarView

**Files:**
- Create: `Vantage/App/SidebarView.swift`

- [ ] **Step 1: Create SidebarView.swift**

  ```swift
  import SwiftUI

  struct SidebarView: View {
      @Environment(AppState.self) private var appState
      @Binding var showSettings: Bool

      var body: some View {
          VStack(spacing: 4) {
              ForEach(Module.allCases) { module in
                  SidebarButton(
                      module: module,
                      isSelected: appState.activeModule == module
                  ) {
                      appState.activeModule = module
                  }
              }
              Spacer()
              Button {
                  showSettings = true
              } label: {
                  Image(systemName: "gearshape")
                      .font(.system(size: 16, weight: .medium))
                      .frame(width: 36, height: 36)
                      .foregroundStyle(.secondary)
              }
              .buttonStyle(.plain)
              .padding(.bottom, 8)
          }
          .padding(.top, 8)
          .frame(width: 52)
      }
  }

  private struct SidebarButton: View {
      let module: Module
      let isSelected: Bool
      let action: () -> Void

      var body: some View {
          Button(action: action) {
              Image(systemName: module.icon)
                  .font(.system(size: 16, weight: .medium))
                  .frame(width: 36, height: 36)
                  .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
                  .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                  .clipShape(RoundedRectangle(cornerRadius: 8))
          }
          .buttonStyle(.plain)
          .help(module.title)
      }
  }
  ```

- [ ] **Step 2: Build**

  ```bash
  xcodebuild -scheme Vantage -configuration Debug build 2>&1 | tail -3
  ```
  Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

  ```bash
  git add Vantage/App/SidebarView.swift
  git commit -m "feat: add SidebarView with module navigation"
  ```

---

## Task 9: StatusBarView

**Files:**
- Create: `Vantage/App/StatusBarView.swift`

- [ ] **Step 1: Create StatusBarView.swift**

  ```swift
  import SwiftUI

  struct StatusBarView: View {
      @Environment(AppState.self) private var appState

      var body: some View {
          HStack(spacing: 12) {
              StatusPill(icon: "cpu", value: appState.cpuUsage, color: .green)
              StatusPill(icon: "memorychip", value: appState.ramUsage, color: .blue)
              Spacer()
              BatteryIndicator(level: appState.batteryLevel, isCharging: appState.isCharging)
          }
          .padding(.horizontal, 12)
          .frame(height: 36)
          .background(.regularMaterial)
      }
  }

  private struct StatusPill: View {
      let icon: String
      let value: Double
      let color: Color

      var body: some View {
          HStack(spacing: 4) {
              Image(systemName: icon)
                  .font(.system(size: 10))
                  .foregroundStyle(.secondary)
              GeometryReader { geo in
                  ZStack(alignment: .leading) {
                      Capsule().fill(Color.secondary.opacity(0.2))
                      Capsule().fill(color.opacity(0.7))
                          .frame(width: geo.size.width * value)
                  }
              }
              .frame(width: 48, height: 4)
              Text(String(format: "%.0f%%", value * 100))
                  .font(.system(size: 10, design: .monospaced))
                  .foregroundStyle(.secondary)
                  .frame(width: 28, alignment: .trailing)
          }
      }
  }

  private struct BatteryIndicator: View {
      let level: Double
      let isCharging: Bool

      var icon: String {
          if isCharging { return "battery.100percent.bolt" }
          switch level {
          case 0..<0.2: return "battery.0percent"
          case 0.2..<0.5: return "battery.25percent"
          case 0.5..<0.8: return "battery.50percent"
          default: return "battery.75percent"
          }
      }

      var body: some View {
          HStack(spacing: 3) {
              Image(systemName: icon)
                  .font(.system(size: 12))
                  .foregroundStyle(level < 0.2 ? .red : .secondary)
              Text(String(format: "%.0f%%", level * 100))
                  .font(.system(size: 10, design: .monospaced))
                  .foregroundStyle(.secondary)
          }
      }
  }
  ```

- [ ] **Step 2: Build**

  ```bash
  xcodebuild -scheme Vantage -configuration Debug build 2>&1 | tail -3
  ```
  Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

  ```bash
  git add Vantage/App/StatusBarView.swift
  git commit -m "feat: add StatusBarView with CPU/RAM/battery"
  ```

---

## Task 10: MenubarView — compose everything

**Files:**
- Create: `Vantage/App/MenubarView.swift`
- Create: `Vantage/App/SettingsView.swift`

- [ ] **Step 1: Create SettingsView.swift (skeleton)**

  ```swift
  import SwiftUI

  struct SettingsView: View {
      var body: some View {
          TabView {
              ForEach(Module.allCases) { module in
                  Text("\(module.title) settings — coming soon")
                      .tabItem {
                          Label(module.title, systemImage: module.icon)
                      }
              }
          }
          .frame(width: 600, height: 480)
      }
  }
  ```

- [ ] **Step 2: Create MenubarView.swift**

  ```swift
  import SwiftUI

  struct MenubarView: View {
      @Environment(AppState.self) private var appState
      @State private var showSettings = false

      var body: some View {
          VStack(spacing: 0) {
              HStack(spacing: 0) {
                  SidebarView(showSettings: $showSettings)
                  Divider()
                  ModuleContentView()
                      .frame(maxWidth: .infinity, maxHeight: .infinity)
              }
              Divider()
              StatusBarView()
          }
          .frame(width: 400, height: 520)
          .background(.ultraThinMaterial)
          .sheet(isPresented: $showSettings) {
              SettingsView()
          }
      }
  }
  ```

- [ ] **Step 3: Build**

  ```bash
  xcodebuild -scheme Vantage -configuration Debug build 2>&1 | tail -3
  ```
  Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

  ```bash
  git add Vantage/App/MenubarView.swift Vantage/App/SettingsView.swift
  git commit -m "feat: compose MenubarView with sidebar, content, status bar"
  ```

---

## Task 11: AppDelegate — wire NSStatusItem + NSPopover

**Files:**
- Create: `Vantage/App/AppDelegate.swift`
- Modify: `Vantage/App/VantageApp.swift`

- [ ] **Step 1: Create AppDelegate.swift**

  ```swift
  import AppKit
  import SwiftUI

  @MainActor
  final class AppDelegate: NSObject, NSApplicationDelegate {
      private var statusItem: NSStatusItem!
      private var popover: NSPopover!
      private let appState = AppState()
      private var pollingTimer: Timer?

      func applicationDidFinishLaunching(_ notification: Notification) {
          NSApp.setActivationPolicy(.accessory)
          Permissions.requestAccessibilityIfNeeded()
          setupStatusItem()
          setupPopover()
          startPolling()
      }

      private func setupStatusItem() {
          statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
          guard let button = statusItem.button else { return }
          button.image = NSImage(systemSymbolName: "square.grid.2x2.fill",
                                  accessibilityDescription: "Vantage")
          button.image?.isTemplate = true
          button.action = #selector(togglePopover)
          button.target = self
      }

      private func setupPopover() {
          popover = NSPopover()
          popover.contentSize = NSSize(width: 400, height: 520)
          popover.behavior = .transient
          popover.animates = true
          popover.contentViewController = NSHostingController(
              rootView: MenubarView().environment(appState)
          )
      }

      private func startPolling() {
          pollingTimer = StatusPoller.startPolling(appState: appState)
      }

      @objc private func togglePopover() {
          guard let button = statusItem.button else { return }
          if popover.isShown {
              popover.performClose(nil)
          } else {
              NSApp.activate(ignoringOtherApps: true)
              popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
          }
      }

      func applicationWillTerminate(_ notification: Notification) {
          pollingTimer?.invalidate()
      }
  }
  ```

- [ ] **Step 2: Replace VantageApp.swift**

  Open `Vantage/App/VantageApp.swift` and replace its contents:
  ```swift
  import SwiftUI

  @main
  struct VantageApp: App {
      @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

      var body: some Scene {
          // Settings window opened via sheet inside MenubarView;
          // this empty Settings scene keeps SwiftUI lifecycle happy.
          Settings { EmptyView() }
      }
  }
  ```

- [ ] **Step 3: Build and run**

  ```bash
  xcodebuild -scheme Vantage -configuration Debug build 2>&1 | tail -3
  ```
  Expected: `** BUILD SUCCEEDED **`

  Run the app in Xcode (⌘R). You should see a grid icon appear in your menubar. Click it — the popover should appear with the sidebar and placeholder module content.

- [ ] **Step 4: Commit**

  ```bash
  git add Vantage/App/AppDelegate.swift Vantage/App/VantageApp.swift
  git commit -m "feat: wire NSStatusItem + NSPopover, start polling"
  ```

---

## Task 12: Final smoke test

- [ ] **Step 1: Run all tests**

  ```bash
  xcodebuild test -scheme Vantage -destination 'platform=macOS' 2>&1 | grep -E "(passed|failed|error:)"
  ```
  Expected: all test suites pass, no errors.

- [ ] **Step 2: Manual verification checklist**

  Run the app (⌘R in Xcode) and verify:
  - [ ] Grid icon appears in menubar (not in Dock)
  - [ ] Click icon → popover opens at 400×520
  - [ ] 10 sidebar icons visible; clicking each switches the content area
  - [ ] Gear icon at bottom → settings sheet opens with module tabs
  - [ ] CPU and RAM bars update every 2 seconds
  - [ ] Battery percentage shows correctly (or 100% on desktop)
  - [ ] Popover closes when clicking outside it

- [ ] **Step 3: Final commit**

  ```bash
  git add -A
  git commit -m "feat: vantage foundation complete — menubar, popover, 10 module placeholders"
  ```

---

## What's Next

This plan delivers a working app skeleton. Each module now gets its own implementation plan:

| Plan | Module |
|------|--------|
| `2026-04-22-window-manager.md` | Window Manager (AXUIElement, snap zones) |
| `2026-04-22-clipboard-history.md` | Clipboard History (NSPasteboard, SQLite) |
| `2026-04-22-system-monitor.md` | System Monitor (processes, disk cleaner) |
| `2026-04-22-app-launcher.md` | App Launcher (NSMetadataQuery, global hotkey) |
| `2026-04-22-focus.md` | Focus / Pomodoro (timer, /etc/hosts blocking) |
| `2026-04-22-display-controls.md` | Display Controls (CoreDisplay, Night Shift) |
| `2026-04-22-text-snippets.md` | Text Snippets (CGEventTap, expander) |
| `2026-04-22-ai-assistant.md` | AI Assistant (Keychain, OpenAI/Anthropic API) |
| `2026-04-22-network-tools.md` | Network Tools (NetworkStatistics, DNS) |
| `2026-04-22-battery-power.md` | Battery & Power (IOKit, charge history) |

Start with Window Manager — it's the flagship feature and the most technically interesting.

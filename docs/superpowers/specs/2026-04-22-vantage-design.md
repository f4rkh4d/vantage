# Vantage — Design Spec
*2026-04-22*

## Overview

Vantage is a free, open-source native macOS menubar utility that consolidates 10 system tools into a single lightweight app. It targets power users who want full control over their Mac from one place without paying for it. Built with Swift + SwiftUI, distributed as a direct `.dmg` (full API access) and eventually on the Mac App Store (sandbox-compatible subset).

---

## Architecture

**Pattern:** Monolithic SwiftUI app, single Xcode target. Each module lives in its own folder (`Modules/<Name>/`) with three files: `View.swift`, `Manager.swift`, `Model.swift`. A single `AppState` (`@Observable`) acts as shared state — all modules read and write to it. No singletons.

**Persistence:**
- `UserDefaults` — per-module settings, keyboard shortcuts, user preferences
- SQLite (via `GRDB.swift`) — clipboard history (timestamps, content, type, app source)
- `NSUbiquitousKeyValueStore` — iCloud sync for settings and snippets

**Permissions required:**
- Accessibility (AX) — window manager, text snippets via CGEventTap
- Full Disk Access — disk cleaner
- Network Extension entitlement — DNS switcher, bandwidth monitor (added as separate target later)

**Project structure:**
```
Vantage/
  App/
    VantageApp.swift        # @main, NSStatusItem setup
    AppState.swift          # @Observable shared state
    MenubarView.swift       # Popover root: sidebar + module content
  Modules/
    WindowManager/
    ClipboardHistory/
    SystemMonitor/
    AppLauncher/
    Focus/
    DisplayControls/
    TextSnippets/
    AIAssistant/
    NetworkTools/
    BatteryPower/
  Shared/
    HotkeyEngine.swift      # Global hotkey registration (CGEventTap)
    Permissions.swift       # AX + Full Disk access prompts
    iCloudSync.swift
  Resources/
    Assets.xcassets
```

---

## UI

**Menubar icon:** SF Symbol `square.grid.2x2.fill`, adaptive to light/dark mode. Shows status indicator dot when Focus mode is active.

**Popover:** 400 × 520pt, `NSPopover` with `.transient` behavior. Structure:
- Left sidebar (60pt wide): icon-only navigation, one button per module + gear at bottom
- Right content area (340pt): active module's View
- Persistent mini status bar at popover bottom: CPU%, RAM%, battery%

**Settings window:** Separate `NSWindow` (600 × 480pt), per-module tabs, opened via gear icon.

**Visual style:** Native macOS — `NSVisualEffectView` blur background, system accent color, SF Symbols throughout. Supports both light and dark mode automatically.

---

## Modules

### 1. Window Manager
- Snap zones: halves, thirds, quarters, 2/3 + 1/3, fullscreen, center float
- Custom zones: user draws their own layout on a display preview
- Keyboard shortcuts: fully configurable, stored in UserDefaults
- Multi-display aware: zones adapt per-screen
- API: `AXUIElement` to move/resize windows, `CGWindowListCopyWindowInfo` to enumerate

### 2. Clipboard History
- Polls `NSPasteboard` every 0.5s, stores new items to SQLite
- Types: plain text, rich text, images, file paths
- UI: searchable list, click to copy, ⌘+number for quick paste
- Pin items to prevent expiration
- Stores last 1000 items by default (configurable)

### 3. System Monitor
- Real-time CPU, RAM, network in/out, disk read/write
- Process list grouped by app, sorted by CPU or RAM
- Kill process button
- Disk cleaner: scans caches, logs, derived data — shows size before deleting
- API: `sysctl`, `host_processor_info`, `IOKit` for disk stats

### 4. App Launcher
- Type to search installed apps + recent documents + running processes
- Keyboard-only navigation: arrows to select, Return to open
- Custom shortcuts: assign global hotkey to launch any app
- Activated via global shortcut (default: ⌥Space)
- API: `NSWorkspace`, `LSCopyAllApplicationURLs`, `Spotlight` via `NSMetadataQuery`

### 5. Focus / Pomodoro
- Pomodoro timer: configurable work/break intervals
- Session stats: focus time today, streak
- Website blocking: writes to `/etc/hosts` (requires helper tool with elevated privileges)
- Auto-enable macOS Focus mode via `EventKit` / Focus API
- Menubar icon shows remaining time when active

### 6. Display Controls
- Brightness slider per display
- Night Shift toggle + schedule
- Resolution switching per display
- Mirror / extend toggle
- Picture-in-picture shortcut
- API: `CoreDisplay` / `DisplayServices` (private framework, available without sandbox)

### 7. Text Snippets
- Define abbreviation → expanded text (e.g. `@@` → email address)
- Variables: `{date}`, `{time}`, `{clipboard}`
- Activates via `CGEventTap`, intercepts keystrokes, replaces abbreviation
- iCloud sync for snippet library
- Import/export as JSON

### 8. AI Assistant
- User provides their own API key (OpenAI or Anthropic)
- Actions: rewrite, summarize, translate, explain selected text
- Triggered by: selecting text + global shortcut
- Response shown in floating panel near cursor
- Keys stored in macOS Keychain

### 9. Network Tools
- Current network: IP, DNS, interface, signal strength (Wi-Fi)
- Per-app bandwidth usage (read from `NetworkStatistics` private API or `nettop`)
- DNS preset switcher: Cloudflare, Google, custom
- Ping monitor: check host latency on interval
- VPN status display (read-only, toggle via `NEVPNManager`)
- Note: DNS change requires admin privileges — uses privileged helper tool (SMJobBless)

### 10. Battery & Power
- Battery percentage, time remaining, charge cycle count
- Charge limit: warn at 80% (soft — no hardware limiter without third-party driver)
- Power mode selector: Low Power, Automatic, High Performance
- Thermal state indicator: nominal / fair / serious / critical
- Charging history chart (last 7 days, stored locally)
- API: `IOKit` `IOPowerSources`, `IOServiceGetMatchingService`

---

## Distribution

**Phase 1 — Direct `.dmg`:**
Full entitlements: Accessibility, Full Disk Access, Network Extension, Hardened Runtime. Signed with Developer ID. Auto-update via Sparkle framework.

**Phase 2 — Mac App Store:**
Separate target with sandbox entitlements. Modules that require privileged access (DNS, disk cleaner, website blocking) are disabled or replaced with sandbox-safe alternatives.

---

## Out of Scope

- Windows / Linux support
- Mobile companion app
- Cloud backend of any kind — everything is local or iCloud
- Paid features — app is fully free and open source

import Foundation
import AppKit
import UserNotifications

enum FocusPhase: String { case idle, work, shortBreak, longBreak }

@MainActor
final class FocusManager: ObservableObject {
    static let shared = FocusManager()
    private init() { requestNotificationPermission() }

    @Published var phase: FocusPhase = .idle
    @Published var timeRemaining: TimeInterval = 25 * 60
    @Published var completedPomodoros: Int = 0
    @Published var workDuration: TimeInterval = 25 * 60
    @Published var shortBreakDuration: TimeInterval = 5 * 60
    @Published var longBreakDuration: TimeInterval = 15 * 60

    private var timer: Timer?

    var isActive: Bool { phase != .idle }
    var isRunning: Bool { timer != nil }
    var progress: Double {
        let total = totalDuration(for: phase)
        return total > 0 ? 1.0 - timeRemaining / total : 0
    }

    func start() {
        timer?.invalidate()
        timer = nil
        if phase == .idle { phase = .work; timeRemaining = workDuration }
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.tick() }
        }
    }

    func pause() { timer?.invalidate(); timer = nil }

    func reset() {
        pause()
        phase = .idle
        timeRemaining = workDuration
        completedPomodoros = 0
    }

    func skip() {
        pause()
        advance()
        start()
    }

    private func tick() {
        timeRemaining -= 1
        if timeRemaining <= 0 { complete() }
    }

    private func complete() {
        pause()
        notify()
        advance()
        start()
    }

    private func advance() {
        switch phase {
        case .work:
            completedPomodoros += 1
            phase = completedPomodoros % 4 == 0 ? .longBreak : .shortBreak
            timeRemaining = phase == .longBreak ? longBreakDuration : shortBreakDuration
        case .shortBreak, .longBreak:
            phase = .work
            timeRemaining = workDuration
        case .idle:
            phase = .work
            timeRemaining = workDuration
        }
    }

    private func totalDuration(for phase: FocusPhase) -> TimeInterval {
        switch phase {
        case .work: return workDuration
        case .shortBreak: return shortBreakDuration
        case .longBreak: return longBreakDuration
        case .idle: return workDuration
        }
    }

    private func notify() {
        let content = UNMutableNotificationContent()
        content.sound = .default
        switch phase {
        case .work:
            content.title = "Focus complete!"
            content.body = "Time for a break."
        case .shortBreak, .longBreak:
            content.title = "Break over"
            content.body = "Ready to focus?"
        case .idle: return
        }
        let req = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(req, withCompletionHandler: nil)
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
}

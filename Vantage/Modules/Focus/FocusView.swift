import SwiftUI

struct FocusView: View {
    @ObservedObject private var manager = FocusManager.shared
    private let accent = Module.focus.accentColor

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                Divider()
                timerSection
                Divider().padding(.top, 8)
                settingsSection
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(accent.opacity(0.12)).frame(width: 30, height: 30)
                Image(systemName: Module.focus.icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(accent)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("Focus")
                    .font(.system(size: 13, weight: .semibold))
                Text(phaseLabel)
                    .font(.system(size: 10)).foregroundStyle(.tertiary)
            }
            Spacer()
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
    }

    private var phaseLabel: String {
        switch manager.phase {
        case .idle: return "Ready"
        case .work: return "Work"
        case .shortBreak: return "Short Break"
        case .longBreak: return "Long Break"
        }
    }

    private var timerSection: some View {
        VStack(spacing: 16) {
            timerRing
                .padding(.top, 20)

            pomodoroDotsView

            HStack(spacing: 10) {
                startPauseButton
                if manager.isActive {
                    skipButton
                }
            }

            if manager.isActive {
                Button("Reset") { manager.reset() }
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 16)
    }

    private var timerRing: some View {
        ZStack {
            Circle()
                .stroke(accent.opacity(0.12), lineWidth: 8)
                .frame(width: 130, height: 130)

            Circle()
                .trim(from: 0, to: manager.progress)
                .stroke(accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 130, height: 130)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.5), value: manager.progress)

            VStack(spacing: 2) {
                Text(formattedTime)
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                Text(phaseLabel)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var formattedTime: String {
        let total = Int(manager.timeRemaining)
        let m = total / 60
        let s = total % 60
        return String(format: "%02d:%02d", m, s)
    }

    private var pomodoroDotsView: some View {
        HStack(spacing: 8) {
            ForEach(0..<4, id: \.self) { i in
                let filled = i < (manager.completedPomodoros % 4 == 0 && manager.completedPomodoros > 0
                                  ? 4 : manager.completedPomodoros % 4)
                Circle()
                    .fill(filled ? accent : Color.secondary.opacity(0.25))
                    .frame(width: 8, height: 8)
            }
        }
    }

    private var startPauseButton: some View {
        Button {
            if manager.isRunning {
                manager.pause()
            } else {
                manager.start()
            }
        } label: {
            Text(manager.isRunning ? "Pause" : (manager.isActive ? "Resume" : "Start"))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 7)
                .background(accent)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var skipButton: some View {
        Button {
            manager.skip()
        } label: {
            Text("Skip")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(accent)
                .padding(.horizontal, 16)
                .padding(.vertical, 7)
                .background(accent.opacity(0.1))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var settingsSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Settings")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.tertiary)
                Spacer()
            }
            .padding(.horizontal, 14).padding(.vertical, 6)
            .background(Color.secondary.opacity(0.05))

            DurationRow(label: "Work", value: $manager.workDuration, accent: accent)
            Divider().padding(.leading, 14)
            DurationRow(label: "Short Break", value: $manager.shortBreakDuration, accent: accent)
            Divider().padding(.leading, 14)
            DurationRow(label: "Long Break", value: $manager.longBreakDuration, accent: accent)
        }
    }
}

private struct DurationRow: View {
    let label: String
    @Binding var value: TimeInterval
    let accent: Color

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            Spacer()
            Button {
                if value > 5 * 60 { value -= 5 * 60 }
            } label: {
                Image(systemName: "minus").font(.system(size: 10, weight: .semibold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(accent)

            Text("\(Int(value / 60)) min")
                .font(.system(size: 11, design: .monospaced))
                .frame(minWidth: 44)

            Button {
                value += 5 * 60
            } label: {
                Image(systemName: "plus").font(.system(size: 10, weight: .semibold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(accent)
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
    }
}

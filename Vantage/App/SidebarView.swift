import SwiftUI
import AppKit

struct SidebarView: View {
    @Environment(AppState.self) private var appState
    @Binding var showSettings: Bool
    @Namespace private var selectionNamespace

    var body: some View {
        VStack(spacing: 0) {
            NoScrollbarScrollView {
                VStack(spacing: 2) {
                    ForEach(Module.allCases) { module in
                        SidebarButton(
                            module: module,
                            isSelected: appState.activeModule == module,
                            namespace: selectionNamespace
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                appState.activeModule = module
                            }
                        }
                    }
                }
                .padding(.vertical, 10)
            }

            Divider().opacity(0.4)

            Button { showSettings = true } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 15, weight: .medium))
                    .frame(width: 36, height: 36)
                    .foregroundStyle(.tertiary)
                    .contentShape(Rectangle())
            }
            .buttonStyle(SidebarGearButtonStyle())
            .help("Settings")
            .padding(.vertical, 6)
        }
        .frame(width: 52)
    }
}

// NSScrollView wrapper that hides both scrollers at the AppKit level.
private struct NoScrollbarScrollView<Content: View>: NSViewRepresentable {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = false
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder

        let host = NSHostingView(rootView: content)
        host.translatesAutoresizingMaskIntoConstraints = false

        scrollView.documentView = host
        NSLayoutConstraint.activate([
            host.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor),
            host.trailingAnchor.constraint(equalTo: scrollView.contentView.trailingAnchor),
        ])

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        if let host = scrollView.documentView as? NSHostingView<Content> {
            host.rootView = content
        }
    }
}

private struct SidebarButton: View {
    let module: Module
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(module.accentColor.opacity(0.15))
                        .matchedGeometryEffect(id: "selection", in: namespace)
                        .overlay(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .stroke(module.accentColor.opacity(0.2), lineWidth: 0.5)
                        )
                }
                Image(systemName: module.icon)
                    .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(
                        isSelected
                            ? AnyShapeStyle(module.accentColor)
                            : AnyShapeStyle(Color.secondary.opacity(isHovered ? 0.9 : 0.6))
                    )
                    .scaleEffect(isHovered && !isSelected ? 1.08 : 1.0)
                    .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isHovered)
            }
            .frame(width: 36, height: 36)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(module.title)
        .onHover { isHovered = $0 }
        .padding(.horizontal, 8)
    }
}

private struct SidebarGearButtonStyle: ButtonStyle {
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : (isHovered ? 1.1 : 1.0))
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
            .onHover { isHovered = $0 }
    }
}

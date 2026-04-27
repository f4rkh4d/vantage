import SwiftUI

struct SidebarView: View {
    @Environment(AppState.self) private var appState
    @Binding var showSettings: Bool
    @Namespace private var selectionNamespace

    private let modules = Module.allCases
    private let gearHeight: CGFloat = 44   // divider + button area
    private let topPad: CGFloat = 8
    private let iconSize: CGFloat = 34

    var body: some View {
        GeometryReader { geo in
            let available = geo.size.height - gearHeight - topPad
            let count = CGFloat(modules.count)
            // spacing can go negative (overlap) if truly needed, but floor at -2
            let spacing = max(-2, (available - count * iconSize) / max(count - 1, 1))

            VStack(spacing: 0) {
                VStack(spacing: spacing) {
                    ForEach(modules) { module in
                        SidebarButton(
                            module: module,
                            isSelected: appState.activeModule == module,
                            namespace: selectionNamespace,
                            size: iconSize
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                appState.activeModule = module
                            }
                        }
                    }
                }
                .padding(.top, topPad)

                Spacer(minLength: 0)

                Divider().opacity(0.4)

                Button { showSettings = true } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 14, weight: .medium))
                        .frame(width: iconSize, height: iconSize)
                        .foregroundStyle(.tertiary)
                        .contentShape(Rectangle())
                }
                .buttonStyle(SidebarGearButtonStyle())
                .help("Settings")
                .frame(height: gearHeight)
            }
        }
        .frame(width: 52)
    }
}

private struct SidebarButton: View {
    let module: Module
    let isSelected: Bool
    let namespace: Namespace.ID
    let size: CGFloat
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(module.accentColor.opacity(0.15))
                        .matchedGeometryEffect(id: "selection", in: namespace)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(module.accentColor.opacity(0.2), lineWidth: 0.5)
                        )
                }
                Image(systemName: module.icon)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(
                        isSelected
                            ? AnyShapeStyle(module.accentColor)
                            : AnyShapeStyle(Color.secondary.opacity(isHovered ? 0.9 : 0.6))
                    )
                    .scaleEffect(isHovered && !isSelected ? 1.08 : 1.0)
                    .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isHovered)
            }
            .frame(width: size, height: size)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(module.title)
        .onHover { isHovered = $0 }
        .padding(.horizontal, 9)
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

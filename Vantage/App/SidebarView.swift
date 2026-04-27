import SwiftUI

struct SidebarView: View {
    @Environment(AppState.self) private var appState
    @Binding var showSettings: Bool
    @Namespace private var selectionNamespace

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical) {
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
                .padding(.top, 10)
            }
            .scrollIndicators(.hidden)

            Divider().opacity(0.4)

            // Settings gear
            Button {
                showSettings = true
            } label: {
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

private struct SidebarButton: View {
    let module: Module
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            ZStack {
                // Selection background with matchedGeometryEffect for smooth slide
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

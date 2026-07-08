import SwiftUI

@main
struct AgentPulseApp: App {
    @State private var container = AppContainer.shared
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView(viewModel: container.sessionViewModel, openWindow: openWindow)
        } label: {
            MenuBarIcon(status: container.sessionViewModel.menuBarStatus)
        }
        .menuBarExtraStyle(.window)

        Window("Preferences", id: "preferences") {
            PreferencesView(viewModel: container.sessionViewModel)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }

    init() {
        Task { @MainActor in
            await AppContainer.shared.bootstrap()
        }
    }
}

// MARK: - Menu Bar Icon

/// Renders the pulse waveform + status dot using SwiftUI Canvas.
/// Geometry is fixed; only the dot color changes per status.
struct MenuBarIcon: View {
    let status: MenuBarStatus

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 14, weight: .bold))
            // Use symbolRenderingMode(.palette) to force actual color rendering
            // in MenuBarExtra which otherwise applies template (monochrome) mode
            Image(systemName: "circle.fill")
                .font(.system(size: 8))
                .symbolRenderingMode(.palette)
                .foregroundStyle(dotColor, dotColor)
        }
        .fixedSize()
    }

    private var dotColor: Color {
        switch status {
        case .idle:       return Color(red: 0.69, green: 0.69, blue: 0.69)
        case .running:    return Color(red: 0.04, green: 0.52, blue: 1.00)
        case .waiting:    return Color(red: 1.00, green: 0.62, blue: 0.04)
        case .permission: return Color(red: 1.00, green: 0.27, blue: 0.23)
        }
    }
}

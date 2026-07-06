import SwiftUI

@main
struct AgentPulseApp: App {
    @State private var container = AppContainer.shared

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView(viewModel: container.sessionViewModel)
        } label: {
            MenuBarLabel(status: container.sessionViewModel.menuBarStatus)
        }
        .menuBarExtraStyle(.window)

        Settings {
            PreferencesView(viewModel: container.sessionViewModel)
        }
    }

    init() {
        // bootstrap() is @MainActor — dispatch from the nonisolated init
        Task { @MainActor in
            await AppContainer.shared.bootstrap()
        }
    }
}

/// The icon shown in the system menu bar.
struct MenuBarLabel: View {
    let status: MenuBarStatus

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "circle.fill")
                .foregroundStyle(iconColor)
                .font(.system(size: 10))
        }
    }

    private var iconColor: Color {
        switch status {
        case .idle:       return .green
        case .permission: return .red
        }
    }
}

import SwiftUI

struct MenuBarContentView: View {
    @Bindable var viewModel: SessionViewModel
    let openWindow: OpenWindowAction

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            if viewModel.sessions.isEmpty {
                emptyState
            } else {
                sessionList
            }
            Divider()
            footer
        }
        .frame(minWidth: 320)
        .onAppear { viewModel.start() }
        .onDisappear { viewModel.stop() }
    }

    // MARK: - Subviews

    private var header: some View {
        HStack {
            MenuBarStatusIcon(status: viewModel.menuBarStatus)
            Text("Agent Pulse")
                .font(.headline)
            Spacer()
            if !viewModel.sessions.isEmpty {
                Text("\(viewModel.sessions.filter(\.needsAttention).count)")
                    .font(.caption.bold())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(badgeColor)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var emptyState: some View {
        Text("No active sessions")
            .foregroundStyle(.secondary)
            .font(.callout)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
    }

    private var sessionList: some View {
        ForEach(viewModel.sessions) { session in
            SessionRowView(session: session) {
                viewModel.focusSession(session)
            }
        }
    }

    private var footer: some View {
        HStack {
            Button {
                openWindow(id: "preferences")
                NSApp.activate(ignoringOtherApps: true)
            } label: {
                Label("Preferences", systemImage: "gear")
                    .font(.callout)
            }
            Spacer()
            Button("Quit") { NSApplication.shared.terminate(nil) }
                .font(.callout)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var badgeColor: Color {
        switch viewModel.menuBarStatus {
        case .idle:       return Color(red: 0.69, green: 0.69, blue: 0.69)
        case .running:    return Color(red: 0.04, green: 0.52, blue: 1.00)
        case .waiting:    return Color(red: 1.00, green: 0.62, blue: 0.04)
        case .permission: return Color(red: 1.00, green: 0.27, blue: 0.23)
        }
    }
}

struct MenuBarStatusIcon: View {
    let status: MenuBarStatus

    var body: some View {
        Image(systemName: "circle.fill")
            .foregroundStyle(color)
            .font(.system(size: 10))
    }

    private var color: Color {
        switch status {
        case .idle:       return Color(red: 0.69, green: 0.69, blue: 0.69)
        case .running:    return Color(red: 0.04, green: 0.52, blue: 1.00)
        case .waiting:    return Color(red: 1.00, green: 0.62, blue: 0.04)
        case .permission: return Color(red: 1.00, green: 0.27, blue: 0.23)
        }
    }
}

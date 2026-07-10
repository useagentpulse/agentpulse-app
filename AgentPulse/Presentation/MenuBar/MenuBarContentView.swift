import SwiftUI

struct MenuBarContentView: View {
    @Bindable var viewModel: SessionViewModel
    let openWindow: OpenWindowAction

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
                .opacity(0.15)
            if viewModel.sessions.isEmpty {
                emptyState
            } else {
                sessionList
            }
            Divider()
                .opacity(0.15)
            footer
        }
        .frame(width: 380)
        .background(.regularMaterial)
        .onAppear { viewModel.start() }
        .onDisappear { viewModel.stop() }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            // Pulse icon
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary.opacity(0.75))

            Text("Agent Pulse")
                .font(.system(size: 13, weight: .semibold))

            Spacer()

            if viewModel.sessions.filter(\.needsAttention).count > 0 {
                Text("\(viewModel.sessions.filter(\.needsAttention).count)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(minWidth: 20, minHeight: 20)
                    .background(badgeColor)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - Session list

    private var emptyState: some View {
        HStack {
            Spacer()
            Text("No active sessions")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.vertical, 20)
    }

    private var sessionList: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.sessions) { session in
                SessionRowView(session: session) {
                    viewModel.focusSession(session)
                }
                if session.id != viewModel.sessions.last?.id {
                    Divider()
                        .opacity(0.08)
                        .padding(.leading, 32)
                }
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Button {
                openWindow(id: "preferences")
                NSApp.activate(ignoringOtherApps: true)
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "gear")
                        .font(.system(size: 11))
                    Text("Preferences")
                        .font(.system(size: 12))
                }
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            Spacer()

            Button("Quit") { NSApplication.shared.terminate(nil) }
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
    }

    // MARK: - Helpers

    private var badgeColor: Color {
        switch viewModel.menuBarStatus {
        case .idle:       return .gray
        case .running:    return Color(red: 0.04, green: 0.52, blue: 1.00)
        case .waiting:    return Color(red: 1.00, green: 0.62, blue: 0.04)
        case .permission: return Color(red: 1.00, green: 0.27, blue: 0.23)
        }
    }
}

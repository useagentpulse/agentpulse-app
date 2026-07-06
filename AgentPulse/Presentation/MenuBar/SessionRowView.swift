import SwiftUI

struct SessionRowView: View {
    let session: Session
    let onFocus: () -> Void

    var body: some View {
        Button(action: onFocus) {
            HStack(spacing: 8) {
                // Status dot only on the left
                Circle()
                    .fill(statusColor)
                    .frame(width: 7, height: 7)

                VStack(alignment: .leading, spacing: 2) {
                    Text(session.projectName)
                        .font(.callout.weight(.medium))
                        .lineLimit(1)
                    HStack(spacing: 4) {
                        ProviderBadgeView(providerName: session.providerName)
                        if let terminal = session.terminalName {
                            Text(terminal)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text(session.cwd)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(session.status.displayName)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(statusColor)
                    Text(relativeTime)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(session.needsAttention ? Color.red.opacity(0.05) : Color.clear)
    }

    private var statusColor: Color {
        switch session.status {
        case .running:           return .green
        case .idle:              return .gray
        case .permissionRequest: return .red
        case .finished:          return .gray
        case .unknown:           return .gray
        }
    }

    private var relativeTime: String {
        let interval = Date().timeIntervalSince(session.lastEventAt)
        if interval < 60 { return "just now" }
        let minutes = Int(interval / 60)
        return "\(minutes)m ago"
    }
}

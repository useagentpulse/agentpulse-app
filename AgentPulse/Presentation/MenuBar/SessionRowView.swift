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
                                .font(.caption.weight(.semibold))
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
        case .running:           return Color(red: 0.04, green: 0.52, blue: 1.00)
        case .idle:              return Color(red: 0.69, green: 0.69, blue: 0.69)
        case .permissionRequest: return Color(red: 1.00, green: 0.27, blue: 0.23)
        case .finished:          return Color(red: 0.69, green: 0.69, blue: 0.69)
        case .unknown:           return Color(red: 0.69, green: 0.69, blue: 0.69)
        }
    }

    private var relativeTime: String {
        let interval = Date().timeIntervalSince(session.lastEventAt)
        switch interval {
        case ..<60:
            return "just now"
        case ..<3600:
            let m = Int(interval / 60)
            return "\(m)m ago"
        case ..<86400:
            let h = Int(interval / 3600)
            let m = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
            return m > 0 ? "\(h)h \(m)m ago" : "\(h)h ago"
        default:
            let d = Int(interval / 86400)
            return "\(d)d ago"
        }
    }
}

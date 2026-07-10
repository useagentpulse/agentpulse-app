import SwiftUI

struct SessionRowView: View {
    let session: Session
    let onFocus: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: onFocus) {
            HStack(alignment: .center, spacing: 10) {

                // Status dot
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                    .shadow(color: statusColor.opacity(0.6), radius: 3)

                // Project info
                VStack(alignment: .leading, spacing: 3) {
                    Text(session.projectName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    HStack(spacing: 5) {
                        ProviderBadgeView(providerName: session.providerName)
                        if let terminal = session.terminalName {
                            Text(terminal)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.secondary)
                        }
                        Text(shortPath)
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }

                Spacer()

                // Status + time
                VStack(alignment: .trailing, spacing: 3) {
                    Text(session.status.displayName)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(statusColor)
                    Text(relativeTime)
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(rowBackground)
        .onHover { isHovered = $0 }
    }

    // MARK: - Helpers

    private var rowBackground: some View {
        Group {
            if session.needsAttention {
                Color(red: 1.0, green: 0.27, blue: 0.23)
                    .opacity(isHovered ? 0.12 : 0.06)
            } else {
                Color.primary
                    .opacity(isHovered ? 0.06 : 0)
            }
        }
        .animation(.easeInOut(duration: 0.12), value: isHovered)
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

    private var shortPath: String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let path = session.cwd.hasPrefix(home)
            ? "~" + session.cwd.dropFirst(home.count)
            : session.cwd
        // Show only last 2 path components to keep it compact
        let parts = path.split(separator: "/").suffix(2).joined(separator: "/")
        return path.hasPrefix("~") && parts.count < path.count ? "~/../\(parts)" : path
    }

    private var relativeTime: String {
        let interval = Date().timeIntervalSince(session.lastEventAt)
        switch interval {
        case ..<60:    return "just now"
        case ..<3600:  return "\(Int(interval / 60))m ago"
        case ..<86400:
            let h = Int(interval / 3600)
            let m = Int(interval.truncatingRemainder(dividingBy: 3600) / 60)
            return m > 0 ? "\(h)h \(m)m ago" : "\(h)h ago"
        default:       return "\(Int(interval / 86400))d ago"
        }
    }
}

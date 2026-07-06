import SwiftUI

/// Small circular letter badge identifying the agent provider (Claude = "C", Gemini = "G", …).
struct ProviderBadgeView: View {
    let providerName: String

    var body: some View {
        Text(letter)
            .font(.system(size: 8, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 14, height: 14)
            .background(color)
            .clipShape(Circle())
    }

    private var letter: String {
        switch providerName {
        case "claude":  return "C"
        case "gemini":  return "G"
        case "codex":   return "X"
        case "aider":   return "A"
        default:        return providerName.prefix(1).uppercased()
        }
    }

    private var color: Color {
        switch providerName {
        case "claude":  return Color(red: 0.851, green: 0.467, blue: 0.341) // Anthropic terracotta
        case "gemini":  return Color(red: 0.259, green: 0.522, blue: 0.957) // Google blue
        case "codex":   return Color(red: 0.118, green: 0.733, blue: 0.388) // OpenAI green
        case "aider":   return Color(red: 0.557, green: 0.267, blue: 0.878) // purple
        default:        return .gray
        }
    }
}

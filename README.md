# Agent Pulse

macOS menu bar app that monitors Claude Code (and future AI agent) sessions and notifies you the moment any session needs your attention.

## Install

```bash
brew tap useagentpulse/agentpulse
brew trust useagentpulse/agentpulse
brew install --cask agentpulse
```

Or download the latest `.dmg` from [Releases](https://github.com/useagentpulse/agentpulse-app/releases).

## How it works

1. On first launch, Agent Pulse installs hooks into `~/.claude/settings.json`
2. When Claude needs your attention, it invokes `agentpulse-hook` (bundled CLI)
3. The hook forwards the event to Agent Pulse over a Unix Domain Socket
4. Agent Pulse updates the session in the menu bar and fires a macOS notification
5. Click the notification or the session row to jump to the exact terminal window

## Requirements

- macOS 14+
- Claude Code (`claude` CLI)

## Build from source

```bash
brew install xcodegen
git clone https://github.com/useagentpulse/agentpulse-app.git
cd agentpulse-app
xcodegen generate
open AgentPulse.xcodeproj
```

Press **⌘R** to run.

## Architecture

Hexagonal Architecture (Ports & Adapters) with DDD layers:

```text
Domain          — pure Swift models + protocol ports (no platform imports)
Application     — use cases + services (NotificationEngine, HookEventDispatcher)
Infrastructure  — adapters: ClaudeProvider, UnixSocketServer, UNNotifications,
                  MacOSTerminalFocuser, MacOSTerminalDetector, LaunchAgent
Presentation    — SwiftUI: MenuBarExtra, SessionRowView, PreferencesView
App             — AgentPulseApp (@main), AppContainer (DI)
AgentPulseHook  — fire-and-forget CLI invoked by Claude hooks
```

### Adding a new agent provider (Gemini, Codex, …)

1. Implement `AgentProviderPort` in `Infrastructure/Adapters/Agent/`
2. Implement `HookInstallerPort` for that provider's config format
3. Register in `AppContainer.providers`

No other changes needed.

## Privacy

- 100% local. No network except `localhost` Unix socket.
- No telemetry, no analytics, no data upload.
- Only session metadata is stored — never prompt text or AI responses.

## Contributing

PRs welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.


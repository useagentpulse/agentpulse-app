# Agent Pulse

macOS menu bar app that monitors Claude Code sessions and notifies you the moment any session needs your attention.

## Requirements

- macOS 14+
- Xcode 16+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

## Build

```bash
brew install xcodegen
cd "Agent Pulse"
xcodegen generate
open AgentPulse.xcodeproj
```

Then press **⌘R** in Xcode to run.

## Architecture

Hexagonal Architecture (Ports & Adapters) with DDD layers:

```
Domain          — pure Swift models + protocol ports (no platform imports)
Application     — use cases: ProcessHookEvent, FocusSession, InstallHooks, PurgeExpiredSessions
                  services: NotificationEngine, HookEventDispatcher
Infrastructure  — macOS adapters: ClaudeProvider, ClaudeHookInstaller, UnixSocketServer,
                  UNNotificationAdapter, MacOSTerminalFocuser, SMAppServiceLaunchAgent
Presentation    — SwiftUI: MenuBarContentView, SessionRowView, PreferencesView, SessionViewModel
App             — AgentPulseApp (@main), AppContainer (DI), NotificationResponseHandler
```

### Adding a new agent provider (Gemini, Codex, …)

1. Implement `AgentProviderPort` in a new file under `Infrastructure/Adapters/Agent/`.
2. Implement `HookInstallerPort` for that provider's config file format.
3. Register the provider in `AppContainer.providers`.

No other code changes required.

## How it works

1. On first launch, `ClaudeHookInstaller` merges a `Notification` hook into `~/.claude/settings.json`.
2. When Claude fires the hook, it invokes `agentpulse-hook` (bundled CLI tool).
3. `agentpulse-hook` reads stdin and writes the payload to the Unix Domain Socket — then exits immediately (zero latency for Claude).
4. The main app receives the event, updates the session registry, and fires a macOS notification if the session transitions to `Waiting` or `PermissionRequest`.
5. Clicking the notification activates the correct terminal window.

## Tests

```bash
xcodebuild test -scheme AgentPulse -destination "platform=macOS"
```

## Privacy

- 100% local. No network calls except `127.0.0.1` localhost socket.
- No telemetry. No analytics. No data upload.
- Only session metadata is stored — never prompt text or Claude responses.

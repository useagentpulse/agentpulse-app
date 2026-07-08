# CLAUDE.md — Agent Pulse

## Project Overview

Agent Pulse is a macOS menu bar app that monitors AI coding agent sessions (Claude Code, future: Gemini, Codex) and notifies the user when any session needs attention.

- **Repo:** [github.com/useagentpulse/agentpulse-app](https://github.com/useagentpulse/agentpulse-app)
- **Platform:** macOS 14+, Swift 6.0, SwiftUI, MenuBarExtra
- **Bundle ID:** `com.agentpulse.AgentPulse`
- **Current version:** 1.0.0

---

## Build System

**XcodeGen** — never edit `.xcodeproj` directly.

```bash
# After adding/removing files or changing project.yml:
xcodegen generate

# Then open in Xcode:
open AgentPulse.xcodeproj
```

**Three targets:**
- `AgentPulse` — menu bar app
- `AgentPulseHook` (product name: `agentpulse-hook`) — fire-and-forget CLI tool
- `AgentPulseTests` — Swift Testing unit tests

**Debug build phase** automatically copies the `.app` to `/Applications/AgentPulse.app` on every build.

**After each build, relaunch the app:**
```bash
pkill AgentPulse && open /Applications/AgentPulse.app
```

---

## Architecture

Hexagonal Architecture (Ports & Adapters) with DDD layers. **The Domain layer must never import AppKit, SwiftUI, or any platform framework.**

```
AgentPulse/
├── Domain/
│   ├── Models/          # Pure Swift value types — Session, SessionStatus, HookEvent, etc.
│   └── Ports/           # Protocol ports — SessionRepositoryPort, NotificationPort, etc.
├── Application/
│   ├── UseCases/        # ProcessHookEventUseCase, FocusSessionUseCase, etc.
│   └── Services/        # NotificationEngine, HookEventDispatcher
├── Infrastructure/
│   └── Adapters/
│       ├── Agent/       # ClaudeProvider, ClaudeHookInstaller
│       ├── Notification/ # UNNotificationAdapter
│       ├── Storage/     # InMemorySessionRepository, UserDefaultsSettingsRepository
│       └── Terminal/    # MacOSTerminalFocuser, MacOSTerminalDetector
│   ├── Lifecycle/       # SMAppServiceLaunchAgent
│   └── Socket/          # UnixSocketServer (POSIX)
├── Presentation/
│   ├── MenuBar/         # MenuBarContentView, SessionRowView, SessionViewModel, ProviderBadgeView
│   └── Preferences/     # PreferencesView
├── App/                 # AgentPulseApp (@main), AppContainer (DI root), NotificationResponseHandler
└── Resources/           # Info.plist, Assets.xcassets, AgentPulse.entitlements, Icons/

AgentPulseHook/
└── Sources/main.swift   # Standalone CLI — reads stdin, injects PIDs, writes to socket

AgentPulseTests/
├── Domain/              # SessionStatusTests
├── Application/         # NotificationEngineTests
└── Infrastructure/      # ClaudeProviderTests, InMemorySessionRepositoryTests, ClaudeHookInstallerTests
```

---

## Dependency Injection

`AppContainer` is the single composition root — a `@MainActor` singleton that lazily wires all dependencies. No DI framework is used.

**Never instantiate infrastructure types outside `AppContainer`.** If a new adapter is needed, add it there.

---

## Session Lifecycle

```
UserPromptSubmit hook  →  running  (blue dot)
PreToolUse / PostToolUse hook  →  running
Notification hook (permission_prompt)  →  permissionRequest  (red dot) + notification
Notification hook (idle_prompt)  →  idle  (grey dot)
Stop hook  →  idle
```

Session is removed from the UI when `kill(claudePID, 0)` returns non-zero (process is dead). Falls back to 30-minute staleness window if no PID is available.

---

## IPC

- **Socket path:** `~/Library/Application Support/AgentPulse/daemon.sock`
- **Protocol:** newline-delimited JSON over Unix Domain Socket (POSIX, not NWListener)
- **`agentpulse-hook`** is invoked by Claude, reads hook JSON from stdin, injects `_claude_pid`, `_hook_ppid`, `_hook_tty`, writes to socket, exits immediately (fire-and-forget — never blocks Claude)

---

## Hook Installation

`ClaudeHookInstaller` performs a **safe JSON merge** into `~/.claude/settings.json`:
- Backs up to `~/.claude/settings.agentpulse.bak.json` before every mutation
- Idempotent — removes existing AgentPulse entry before re-adding
- Registers these Claude hooks: `Notification`, `PreToolUse`, `PostToolUse`, `Stop`, `UserPromptSubmit`
- Hook executable path is always `/Applications/AgentPulse.app/Contents/Resources/agentpulse-hook` (stable, not DerivedData)

---

## Adding a New Agent Provider

1. Create `Infrastructure/Adapters/Agent/GeminiProvider.swift` implementing `AgentProviderPort`
2. Create `Infrastructure/Adapters/Agent/GeminiHookInstaller.swift` implementing `HookInstallerPort`
3. Register in `AppContainer.providers`:
   ```swift
   public lazy var providers: [any AgentProviderPort] = [claudeProvider, geminiProvider]
   ```
4. Add badge color in `ProviderBadgeView.swift`

No other changes needed — the dispatcher, session manager, and notification engine are provider-agnostic.

---

## Menu Bar Icon States

| State | Dot color | Meaning |
|---|---|---|
| `idle` | `#B0B0B0` grey | No active attention needed |
| `running` | `#0A84FF` blue | Session actively working |
| `waiting` | `#FF9F0A` orange | Session waiting for user input |
| `permissionRequest` | `#FF453A` red | Session blocked on approval |

Priority (highest wins): `permission > waiting > running > idle`

---

## Terminal Focus

When a session row or notification is clicked, `MacOSTerminalFocuser`:
1. Gets the Claude process TTY via `ps -p <claudePID> -o tty=` at click time
2. Runs AppleScript to find and activate the exact window/tab matching that TTY
3. Supports: Terminal.app (exact tab), iTerm2 (exact session), Warp/Ghostty/VS Code (app activate)

Requires `com.apple.security.automation.apple-events` entitlement (`AgentPulse/Resources/AgentPulse.entitlements`).

---

## Key Files Reference

| File | Purpose |
|---|---|
| `project.yml` | XcodeGen spec — edit this, never `.xcodeproj` |
| `App/AppContainer.swift` | DI root — all wiring lives here |
| `App/AgentPulseApp.swift` | `@main` entry point + `MenuBarIcon` view |
| `Domain/Ports/AgentProviderPort.swift` | Extension point for new providers |
| `Infrastructure/Adapters/Agent/ClaudeProvider.swift` | Claude hook payload parser |
| `Infrastructure/Adapters/Agent/ClaudeHookInstaller.swift` | Merges hooks into `~/.claude/settings.json` |
| `Infrastructure/Socket/UnixSocketServer.swift` | POSIX socket server (actor) |
| `AgentPulseHook/Sources/main.swift` | CLI hook — injected by Claude |
| `scripts/generate_icons.py` | Regenerates all app icon sizes (`pip3 install Pillow`) |
| `scripts/release.sh` | Builds archive, notarizes, creates DMG |

---

## Versioning

In `project.yml`:
```yaml
MARKETING_VERSION: "1.0.0"    # shown to users — bump for releases
CURRENT_PROJECT_VERSION: "1"  # build number — increment by 1 each release
```

After bumping: `xcodegen generate` → `⌘B` in Xcode.

---

## Release Process

```bash
# 1. Bump MARKETING_VERSION and CURRENT_PROJECT_VERSION in project.yml
# 2. xcodegen generate + ⌘B in Xcode
# 3. Build DMG and create GitHub release:
./scripts/release.sh 1.0.1

# 4. Update SHA256 in homebrew-agentpulse tap:
# https://github.com/useagentpulse/homebrew-agentpulse/blob/main/Casks/agentpulse.rb
```

---

## Testing

```bash
xcodebuild test -scheme AgentPulse -destination "platform=macOS"
```

Tests use **Swift Testing** framework (`@Test`, `@Suite`, `#expect`). No mocking frameworks — stubs are hand-written actors in the test files.

---

## Constraints

- **Domain layer**: no AppKit, SwiftUI, or platform imports — pure Swift only
- **Never break Claude**: hook installer always backs up; errors are swallowed, never crash
- **No data upload**: 100% local, only `localhost` Unix socket, no telemetry
- **Never log**: prompt text, Claude responses, or any session content — metadata only
- **Swift 6 strict concurrency**: `SWIFT_STRICT_CONCURRENCY: complete` — all actors must be properly isolated

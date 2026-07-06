# Agent Pulse — Technical Specification (v1)

## Overview

Agent Pulse is a macOS menu bar application that monitors all running Claude Code sessions and immediately notifies the user whenever any session requires user attention.

The application must require zero workflow changes.

Users continue launching Claude exactly as before:

```
claude
```

- No wrapper scripts.
- No aliases.
- No modified shell configuration.
- No replacement executables.

The application integrates exclusively using Claude Code's official Hook API.

---

## Goals

**Primary goal:**

Prevent Claude Code sessions from sitting idle waiting for user input.

**Example:**

| Time  | Event |
|-------|-------|
| 11:00 | Claude Session A starts. |
| 11:03 | User switches to Session B. |
| 11:05 | Session A requests confirmation. |
| 11:15 | User notices. |

10 minutes wasted. Agent Pulse eliminates this.

---

## Non-goals

Do NOT build:

- token monitor
- analytics dashboard
- cost tracker
- orchestration tool
- terminal multiplexer
- transcript viewer
- prompt editor

Version 1 focuses entirely on **notification** and **lightweight session tracking**.

---

## Platform

- macOS 14+
- Swift 6
- SwiftUI
- MenuBarExtra
- LaunchAgent
- XPC or Unix Domain Socket
- **No Electron. No Node runtime.**

---

## High Level Architecture

```
+------------------------+
| Claude Code Sessions   |
+-----------+------------+
            |
            |
      Hook Events
            |
            |
+-----------v------------+
| Hook Receiver          |
+-----------+------------+
            |
            |
    Unix Socket
            |
            |
+-----------v------------+
| Background Daemon      |
|                        |
| Session Manager        |
| Notification Engine    |
| State Store            |
+-----------+------------+
            |
            |
+-----------v------------+
| Menu Bar App           |
+------------------------+
```

---

## Components

### 1. Hook Installer

**Responsibilities**

- Automatically configure Claude Code hooks.
- Never require manual editing.

**On first launch:**

1. detect Claude installation
2. backup existing settings
3. merge hooks
4. preserve existing hooks

**Must support:**

- `~/.claude/settings.json`

Never overwrite user configuration.

**Hook**

Use `Notification` hook. Initially simply POST JSON to local daemon.

**Example:**

```json
{
  "hook": "Notification",
  "session_id": "...",
  "cwd": "...",
  "message": "...",
  "title": "...",
  "notification_type": "permission_prompt"
}
```

**Transport:**

- Preferred: `http://127.0.0.1:4587/event`
- Alternative: Unix Domain Socket

---

### 2. Daemon

Runs as LaunchAgent. Starts on login.

**Responsibilities**

- Receive hook events.
- Maintain session registry.
- Emit notifications.
- Serve state to UI.

---

### 3. Session Model

**Session fields:**

| Field | Type |
|-------|------|
| id | String |
| cwd | String |
| projectName | String |
| startedAt | Date |
| lastEvent | Date |
| status | Status |
| terminal | TerminalInfo |
| lastNotification | Date? |
| transcriptPath | String? |
| title | String |

**Status enum:**

- `Running`
- `Waiting`
- `PermissionRequest`
- `Finished`
- `Unknown`

**Session Registry**

Maintain: `Dictionary<SessionID, Session>`

**Update flow:**

```
Notification received
        ↓
Find Session
        ↓
Update State
        ↓
Notify UI
```

**Expired sessions:** Auto-remove after configurable timeout. Default: 30 minutes after completion.

---

### 4. Notification Engine

**Trigger whenever:**

```
Running → Waiting
     OR
Running → PermissionRequest
```

**Rules:**

- Only notify once until state changes. Never spam.

**Notification:**

- Title: `Claude needs your attention`
- Body: `backend-api / Waiting for input` or `Permission required`
- Buttons: `Open Session`, `Dismiss`

---

### 5. Focus Session

When notification clicked, attempt to activate correct terminal.

**Supported terminals:**

- Terminal.app
- iTerm2
- Warp
- Ghostty
- VSCode Terminal (best effort)

**Terminal Detection**

Store:
- PID
- PPID
- TTY
- Bundle ID
- Window ID (if available)

Can be discovered from parent process chain.

---

### 6. Menu Bar

**Icon:**

| Color | Meaning |
|-------|---------|
| Green | No waiting sessions |
| Yellow | At least one waiting |
| Red | Permission required |

**Badge:** Number of waiting sessions.

**Example menu:**

```
Agent Pulse

● backend-api        Waiting          2m
● frontend           Running
● docs               Permission Required  15s

────────────────────
Preferences
Quit
```

**Preferences:**

- Launch at Login
- Notifications enabled
- Play sound
- Auto focus terminal
- Retention period
- Theme

---

## State Persistence

**Persist to:** `~/Library/Application Support/AgentPulse`

**Store:**
- Recent sessions
- Settings
- Window state

---

## Logging

Structured logging.

**Subsystems:**
- Hook
- Daemon
- Notifications
- SessionManager
- Terminal

**Never log:**
- Prompts
- Claude responses
- Only metadata

---

## Privacy

- Never upload data.
- Entirely local.
- No telemetry.
- No analytics.
- No network except localhost.

---

## Error Handling

| Scenario | Behavior |
|----------|----------|
| Daemon unavailable | Hook retries |
| Claude settings invalid | Restore backup |
| Hook install fails | Show onboarding |

**Never break Claude.**

---

## Hook Installation Algorithm

```
Read settings
      ↓
Parse JSON
      ↓
Locate hooks
      ↓
Merge Notification hook
      ↓
Write atomically
      ↓
Validate
      ↓
Backup previous version
```

---

## Testing

**Unit tests:**
- Session state machine
- Notification deduplication
- Hook parser
- Settings merger

**Integration tests:**
- Receive hook JSON
- Spawn daemon
- Verify UI update
- Verify notification

---

## Future Extension Points

Abstract `AgentProvider` protocol:

```swift
protocol AgentProvider {
    var name: String { get }
    func install()
    func uninstall()
    func parse(event: HookEvent) -> SessionUpdate?
}
```

**Implementations (planned):**

| Provider | Status |
|----------|--------|
| ClaudeProvider | v1 |
| CodexProvider | future |
| GeminiProvider | future |
| AiderProvider | future |

Only Claude implemented in v1.

---

## UI Style

- Minimal.
- Native macOS.
- No windows unless requested.
- Menu bar first.
- Notification first.

**Reference apps:** AirBuddy, Raycast, MonitorControl.

> "Hidden until needed."

---

## Hook Architecture — Recommended Design

> **Key design decision:** The Claude hook should NOT perform an HTTP request directly.

Instead, have it invoke a tiny helper executable: `agentpulse-hook`

The hook payload is passed on stdin. The helper forwards the event to the daemon over a Unix domain socket. If the daemon isn't running, the helper exits immediately without delaying Claude Code.

**Benefits:**
- Fire-and-forget (zero latency for Claude)
- Avoids networking (even localhost HTTP)
- Native macOS architecture (XPC / Unix socket)
- More resilient to daemon restarts

**Claude settings.json hook config:**

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "agentpulse-hook"
          }
        ]
      }
    ]
  }
}
```

---

## Acceptance Criteria

- [ ] User installs app
- [ ] Claude continues working normally
- [ ] No wrapper
- [ ] No alias
- [ ] No shell modification
- [ ] Hook installed automatically
- [ ] Session registry maintained
- [ ] macOS notification appears within one second of Claude waiting
- [ ] Clicking notification opens correct terminal
- [ ] Multiple concurrent Claude sessions supported
- [ ] Zero prompt/response data stored
- [ ] Works offline
- [ ] Native macOS performance

---

## Nice-to-have (Post-v1)

- Dynamic Island support
- Apple Watch notifications
- Menu bar progress indicator
- Session timers / waiting duration
- Snooze notifications
- Session grouping by repository
- Keyboard shortcut to cycle through waiting sessions
- Raycast extension
- Shortcuts integration
- Multi-agent support
- Session search
- Recent completed sessions
- Dock badge
- Focus mode integration
- Slack/Discord notifications

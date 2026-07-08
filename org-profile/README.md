# Agent Pulse

**Monitor your AI coding agents. Never miss when they need you.**

Agent Pulse is an open-source macOS menu bar app that watches all your AI coding agent sessions and notifies you instantly when any session needs your attention.

---

## The Problem

You start a Claude Code session, switch to another task, and 10 minutes later realize it's been waiting for your permission the whole time. Multiplied across multiple sessions and terminals, this is a silent productivity killer.

## The Solution

Agent Pulse sits in your menu bar, monitors all running sessions, and fires a macOS notification the moment any session needs you — with a single click to jump to the exact terminal window.

---

## Projects

| Repo | Description |
|---|---|
| [agentpulse-app](https://github.com/useagentpulse/agentpulse-app) | macOS menu bar app |
| [homebrew-agentpulse](https://github.com/useagentpulse/homebrew-agentpulse) | Homebrew tap |

---

## Install

```bash
brew tap useagentpulse/agentpulse
brew install --cask agentpulse
```

---

## Supported Agents

| Agent | Status |
|---|---|
| Claude Code | ✅ v1.0 |
| Gemini CLI | 🔜 Planned |
| Codex CLI | 🔜 Planned |
| Aider | 🔜 Planned |

---

## Contributing

All contributions welcome. See [agentpulse-app](https://github.com/useagentpulse/agentpulse-app) for guidelines.

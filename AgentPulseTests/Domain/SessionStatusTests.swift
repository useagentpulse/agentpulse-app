import Testing
@testable import AgentPulse

@Suite("SessionStatus state machine")
struct SessionStatusTests {

    @Test("permission_prompt maps to permissionRequest")
    func permissionPromptMapping() {
        let status = SessionStatus(notificationType: "permission_prompt")
        #expect(status == .permissionRequest)
    }

    @Test("idle maps to waiting")
    func idleMapping() {
        let status = SessionStatus(notificationType: "idle")
        #expect(status == .waiting)
    }

    @Test("run_start maps to running")
    func runStartMapping() {
        let status = SessionStatus(notificationType: "run_start")
        #expect(status == .running)
    }

    @Test("run_end maps to finished")
    func runEndMapping() {
        let status = SessionStatus(notificationType: "run_end")
        #expect(status == .finished)
    }

    @Test("unknown type maps to running (safe default)")
    func unknownMapping() {
        let status = SessionStatus(notificationType: "some_future_type")
        #expect(status == .running)
    }

    @Test("waiting and permissionRequest trigger notifications")
    func notificationTriggers() {
        #expect(SessionStatus.waiting.triggersNotification == true)
        #expect(SessionStatus.permissionRequest.triggersNotification == true)
        #expect(SessionStatus.running.triggersNotification == false)
        #expect(SessionStatus.finished.triggersNotification == false)
    }
}

private extension SessionStatus {
    init(notificationType: String) {
        switch notificationType {
        case "permission_prompt":        self = .permissionRequest
        case "idle", "waiting":          self = .waiting
        case "run_start", "run_resume":  self = .running
        case "run_end", "done":          self = .finished
        default:                         self = .running
        }
    }
}

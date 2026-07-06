import Testing
import Foundation
@testable import AgentPulse

@Suite("InMemorySessionRepository")
struct InMemorySessionRepositoryTests {

    @Test("saves and retrieves a session")
    func saveAndFind() async {
        let repo = InMemorySessionRepository()
        let session = makeSession(id: "s1", status: .running)
        await repo.save(session)
        let found = await repo.find(id: "s1")
        #expect(found?.id == "s1")
    }

    @Test("returns all sessions sorted by startedAt")
    func allReturnsSorted() async {
        let repo = InMemorySessionRepository()
        let s1 = makeSession(id: "s1", status: .running, startedAt: Date(timeIntervalSinceNow: -60))
        let s2 = makeSession(id: "s2", status: .running, startedAt: Date(timeIntervalSinceNow: -30))
        await repo.save(s2)
        await repo.save(s1)
        let all = await repo.all()
        #expect(all.map(\.id) == ["s1", "s2"])
    }

    @Test("removes session by id")
    func removeById() async {
        let repo = InMemorySessionRepository()
        await repo.save(makeSession(id: "s1", status: .running))
        await repo.remove(id: "s1")
        let found = await repo.find(id: "s1")
        #expect(found == nil)
    }

    @Test("removeExpired removes only finished sessions older than cutoff")
    func removeExpired() async {
        let repo = InMemorySessionRepository()
        let old = makeSession(id: "old", status: .finished, lastEventAt: Date(timeIntervalSinceNow: -3600))
        let recent = makeSession(id: "recent", status: .finished, lastEventAt: Date(timeIntervalSinceNow: -10))
        let running = makeSession(id: "running", status: .running, lastEventAt: Date(timeIntervalSinceNow: -3600))
        await repo.save(old)
        await repo.save(recent)
        await repo.save(running)

        let cutoff = Date(timeIntervalSinceNow: -1800) // 30 min ago
        await repo.removeExpired(before: cutoff)

        let all = await repo.all()
        let ids = Set(all.map(\.id))
        #expect(!ids.contains("old"))
        #expect(ids.contains("recent"))
        #expect(ids.contains("running"))
    }
}

// MARK: - Helpers

private func makeSession(
    id: String,
    status: SessionStatus,
    startedAt: Date = .now,
    lastEventAt: Date = .now
) -> Session {
    Session(
        id: id,
        cwd: "/tmp/\(id)",
        projectName: id,
        startedAt: startedAt,
        lastEventAt: lastEventAt,
        status: status,
        title: id,
        providerName: "claude"
    )
}

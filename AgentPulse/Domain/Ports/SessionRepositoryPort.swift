import Foundation

/// Port — read/write access to the session registry.
public protocol SessionRepositoryPort: AnyObject, Sendable {
    func all() async -> [Session]
    func find(id: SessionID) async -> Session?
    func save(_ session: Session) async
    func remove(id: SessionID) async
    func removeExpired(before date: Date) async
}

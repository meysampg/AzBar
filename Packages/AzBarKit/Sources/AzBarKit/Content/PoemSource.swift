import Foundation

public enum ContentError: Error, Sendable, Equatable {
    case notFound
    case network(String)
    case decoding(String)
}

public protocol PoemSource: Sendable {
    func poet(id: PoetID) async throws -> Poet
    func rootCategory() async throws -> PoemCategory
    func category(id: CategoryID) async throws -> PoemCategory
    func poem(id: PoemID) async throws -> Poem
}

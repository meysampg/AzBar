import Foundation

enum AppTab: Hashable {
    case today, library, review, progress, settings
}

enum LearnMode: Hashable {
    case nextLesson
    case lesson(nodeId: String, coupletIndices: [Int])
    case practice(nodeId: String, coupletIndices: [Int])
    case challenge
}

struct LearnRequest: Identifiable, Hashable {
    let id = UUID()
    let poemId: PoemID
    let poetId: PoetID
    var mode: LearnMode = .nextLesson
}

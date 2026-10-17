import Foundation

enum AppTab: Hashable {
    case today, library, review, settings
}

struct LearnRequest: Identifiable, Hashable {
    let id = UUID()
    let poemId: PoemID
    let poetId: PoetID
}

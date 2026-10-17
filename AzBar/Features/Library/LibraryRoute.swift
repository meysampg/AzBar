// PLACEHOLDER (WP0): WP3 overwrites this file, keeping the enum cases and `libraryDestinations()`
import SwiftUI

enum LibraryRoute: Hashable {
    case poet(PoetID)
    case category(CategoryID, poetId: PoetID)
    case poem(PoemID, poetId: PoetID)
}

extension View {
    /// Registers navigation destinations for `LibraryRoute`.
    func libraryDestinations() -> some View {
        navigationDestination(for: LibraryRoute.self) { route in
            switch route {
            case .poem(let poemId, let poetId):
                ReaderView(poemId: poemId, poetId: poetId)
            case .poet, .category:
                ContentUnavailableView("کتابخانه", systemImage: "books.vertical")
            }
        }
    }
}

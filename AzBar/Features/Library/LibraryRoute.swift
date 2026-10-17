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
            case .poet(let poetId):
                PoetView(poetId: poetId)
            case .category(let categoryId, let poetId):
                CategoryView(categoryId: categoryId, poetId: poetId)
            case .poem(let poemId, let poetId):
                ReaderView(poemId: poemId, poetId: poetId)
            }
        }
    }
}

/// Loading phase shared by the Library screens.
enum LibraryLoadPhase<Value> {
    case loading
    case loaded(Value)
    case failed
}

/// Standard error state for remote content with a retry button.
struct LibraryErrorView: View {
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("اتصال برقرار نشد", systemImage: "wifi.slash")
        } description: {
            Text("اتصال اینترنت را بررسی کنید و دوباره تلاش کنید.")
        } actions: {
            Button("تلاش دوباره", action: retry)
                .buttonStyle(.glass)
        }
    }
}

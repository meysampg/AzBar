import SwiftUI

enum LibraryRoute: Hashable {
    case poet(PoetID)
    case category(CategoryID, poetId: PoetID)
    case poem(PoemID, poetId: PoetID)
    case path(PoemID, poetId: PoetID)
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
            case .path(let poemId, let poetId):
                PoemPathView(poemId: poemId, poetId: poetId)
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
        AzErrorView(retry: retry)
    }
}

/// Round monogram: the first letter of a poet's name.
struct PoetMonogram: View {
    let name: String
    var size: CGFloat = 44

    var body: some View {
        Text(verbatim: String(name.first ?? "ا"))
            .font(.poem(.naskh, size: size * 0.5, bold: true))
            .foregroundStyle(Theme.Palette.teal)
            .frame(width: size, height: size)
            .background(Theme.Palette.tealSoft, in: .circle)
            .accessibilityHidden(true)
    }
}

/// Shared row for a sub-category, with an online chip for remote-only ones.
struct CategoryChildRow: View {
    let child: CategoryRef
    let poetId: PoetID

    var body: some View {
        NavigationLink(value: LibraryRoute.category(child.id, poetId: poetId)) {
            HStack(spacing: Theme.Spacing.m) {
                AzIconBadge("books.vertical", tone: .teal, size: 32)
                Text(verbatim: child.title)
                    .font(.app(.body, weight: .medium))
                    .foregroundStyle(Theme.Palette.ink)
                Spacer(minLength: Theme.Spacing.s)
                if child.isOnlineOnly {
                    AzChip("آنلاین", systemImage: "icloud", tone: .neutral)
                }
            }
            .padding(.vertical, Theme.Spacing.xs)
            .accessibilityElement(children: .combine)
        }
        .listRowBackground(Theme.Palette.card)
    }
}

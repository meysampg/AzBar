import SwiftUI

/// The children (and direct poems) of a poet's root category.
struct PoetView: View {
    let poetId: PoetID

    @Environment(\.contentRepository) private var content
    @Environment(ProgressStore.self) private var progress
    @State private var phase: LibraryLoadPhase<PoemCategory> = .loading
    @State private var poet: Poet?
    @State private var isDescriptionExpanded = false

    private var entry: PoetCatalogEntry? { content.catalog.entry(poetId) }
    private var title: String { entry?.name ?? "" }

    var body: some View {
        Group {
            switch phase {
            case .loading:
                AzLoadingView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failed:
                LibraryErrorView { Task { await load() } }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .loaded(let category):
                list(category)
            }
        }
        .azScreenBackground()
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    private var lifespan: String? {
        guard let birth = entry?.birthYearHijri, let death = entry?.deathYearHijri else { return nil }
        return "\(birth.fa)–\(death.fa) ق"
    }

    private var header: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.l) {
            PoetMonogram(name: entry?.name ?? "", size: 64)
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(verbatim: entry?.fullName ?? title)
                    .font(.azTitle)
                    .foregroundStyle(Theme.Palette.ink)
                    .accessibilityAddTraits(.isHeader)
                if let lifespan {
                    Text(verbatim: lifespan)
                        .font(.azMeta)
                        .foregroundStyle(Theme.Palette.inkSecondary)
                }
                if let description = poet?.description, !description.isEmpty {
                    Text(verbatim: description)
                        .font(.azMeta)
                        .foregroundStyle(Theme.Palette.inkSecondary)
                        .lineLimit(isDescriptionExpanded ? nil : 3)
                    Button(isDescriptionExpanded ? "کمتر" : "بیشتر") {
                        withAnimation(.smooth(duration: 0.25)) { isDescriptionExpanded.toggle() }
                    }
                    .font(.azCaption)
                    .foregroundStyle(Theme.Palette.teal)
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, Theme.Spacing.s)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    private func list(_ category: PoemCategory) -> some View {
        let favorites = Set(progress.favorites().map(\.poemId))
        let planned = Set(progress.activePlans().map(\.poemId))
        return List {
            Section { header }
            if !category.children.isEmpty {
                Section {
                    ForEach(category.children) { child in
                        CategoryChildRow(child: child, poetId: poetId)
                    }
                } header: {
                    AzListHeader("بخش‌ها")
                }
            }
            if !category.poems.isEmpty {
                Section {
                    ForEach(category.poems) { summary in
                        PoemRow(summary: summary, poetId: poetId,
                                isFavorite: favorites.contains(summary.id),
                                isMemorizing: planned.contains(summary.id))
                    }
                } header: {
                    AzListHeader("اشعار")
                }
            }
        }
        .azList()
        .listRowSeparatorTint(Theme.Palette.hairline)
        .overlay {
            if category.children.isEmpty && category.poems.isEmpty {
                AzEmptyState("text.book.closed", "شعری یافت نشد")
            }
        }
    }

    private func load() async {
        phase = .loading
        do {
            phase = .loaded(try await content.rootCategory(poetId: poetId))
        } catch {
            if !Task.isCancelled { phase = .failed }
            return
        }
        poet = try? await content.poet(poetId)
    }
}

#Preview {
    PreviewContainer {
        NavigationStack {
            PoetView(poetId: 2)
                .libraryDestinations()
        }
    }
}

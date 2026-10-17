import SwiftUI

/// Search results for poem titles and mesras, grouped by poet and debounced by 250 ms.
struct SearchResultsView: View {
    let query: String

    @Environment(\.contentRepository) private var content
    @State private var hits: [SearchHit] = []
    @State private var isSearching = false

    private var normalizedLength: Int { PersianText.normalizeForSearch(query).count }

    /// Hits grouped by poet, ordered by catalog `sortOrder`.
    private var groups: [(poet: PoetCatalogEntry?, poetId: PoetID, hits: [SearchHit])] {
        let byPoet = Dictionary(grouping: hits, by: \.poetId)
        let order = content.catalog.enabledPoets
        var result: [(PoetCatalogEntry?, PoetID, [SearchHit])] = order.compactMap { entry in
            byPoet[entry.id].map { (entry, entry.id, $0) }
        }
        let known = Set(order.map(\.id))
        for (id, list) in byPoet where !known.contains(id) { result.append((nil, id, list)) }
        return result
    }

    var body: some View {
        Group {
            if normalizedLength < 2 {
                AzEmptyState("magnifyingglass", "جستجو", "دست‌کم دو حرف بنویسید.")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if isSearching && hits.isEmpty {
                AzLoadingView("در حال جستجو…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if hits.isEmpty {
                AzEmptyState("magnifyingglass", "نتیجه‌ای یافت نشد", "عبارت دیگری را امتحان کنید.")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                resultsList
            }
        }
        .azScreenBackground()
        .task(id: query) {
            guard normalizedLength >= 2 else {
                hits = []
                return
            }
            isSearching = true
            defer { isSearching = false }
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
            let result = await content.search(query)
            guard !Task.isCancelled else { return }
            hits = result
        }
    }

    private var resultsList: some View {
        List {
            ForEach(groups, id: \.poetId) { group in
                Section {
                    ForEach(group.hits) { hit in
                        NavigationLink(value: LibraryRoute.poem(hit.poemId, poetId: hit.poetId)) {
                            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                Text(verbatim: hit.poemTitle)
                                    .font(.azHeadline)
                                    .foregroundStyle(Theme.Palette.ink)
                                Text(verbatim: PersianText.removingDiacritics(hit.matchedText))
                                    .font(.poem(.naskh, size: 16))
                                    .foregroundStyle(Theme.Palette.inkSecondary)
                                    .lineLimit(2)
                            }
                            .padding(.vertical, Theme.Spacing.xs)
                            .accessibilityElement(children: .combine)
                        }
                        .listRowBackground(Theme.Palette.card)
                    }
                } header: {
                    AzListHeader(group.poet?.name ?? "")
                }
            }
        }
        .azList()
    }
}

#Preview {
    PreviewContainer {
        NavigationStack {
            SearchResultsView(query: "عشق")
                .libraryDestinations()
        }
    }
}

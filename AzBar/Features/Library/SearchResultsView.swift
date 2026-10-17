import SwiftUI

/// Search results for poem titles and mesras, debounced by 250 ms.
struct SearchResultsView: View {
    let query: String

    @Environment(\.contentRepository) private var content
    @State private var hits: [SearchHit] = []
    @State private var isSearching = false

    private var normalizedLength: Int { PersianText.normalizeForSearch(query).count }

    var body: some View {
        List {
            ForEach(hits) { hit in
                NavigationLink(value: LibraryRoute.poem(hit.poemId, poetId: hit.poetId)) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text(verbatim: hit.poemTitle)
                            .font(.app(.headline))
                        Text(verbatim: PersianText.removingDiacritics(hit.matchedText))
                            .font(.app(.subheadline))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    .padding(.vertical, Theme.Spacing.xs)
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .overlay {
            if normalizedLength < 2 {
                ContentUnavailableView("جستجو", systemImage: "magnifyingglass",
                                       description: Text("دست‌کم دو حرف بنویسید."))
            } else if isSearching && hits.isEmpty {
                ProgressView()
            } else if hits.isEmpty {
                ContentUnavailableView("نتیجه‌ای یافت نشد", systemImage: "magnifyingglass",
                                       description: Text("عبارت دیگری را امتحان کنید."))
            }
        }
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
}

#Preview {
    PreviewContainer {
        NavigationStack {
            SearchResultsView(query: "عشق")
                .libraryDestinations()
        }
    }
}

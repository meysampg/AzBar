import SwiftUI

/// A poem in a category list: title, one-line excerpt and status icons.
struct PoemRow: View {
    let summary: PoemSummary
    let poetId: PoetID
    var isFavorite: Bool = false
    var isMemorizing: Bool = false

    var body: some View {
        NavigationLink(value: LibraryRoute.poem(summary.id, poetId: poetId)) {
            HStack(spacing: Theme.Spacing.m) {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(verbatim: summary.title)
                        .font(.app(.body, weight: .medium))
                    if let excerpt = summary.excerpt, !excerpt.isEmpty {
                        Text(verbatim: PersianText.removingDiacritics(excerpt))
                            .font(.app(.footnote))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
                if isMemorizing {
                    Image(systemName: "brain.head.profile")
                        .foregroundStyle(.tint)
                        .accessibilityLabel("در حال حفظ")
                }
                if isFavorite {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.pink)
                        .accessibilityLabel("علاقه‌مندی")
                }
            }
            .font(.footnote)
            .padding(.vertical, Theme.Spacing.xs)
        }
    }
}

#Preview {
    PreviewContainer {
        NavigationStack {
            List {
                PoemRow(summary: PoemSummary(id: 2130, categoryId: 24, title: "غزل شمارهٔ ۱",
                                             urlSlug: "sh1", excerpt: "اَلا یا اَیُّهَا السّاقی اَدِرْ کَأساً و ناوِلْها"),
                        poetId: 2, isFavorite: true, isMemorizing: true)
                PoemRow(summary: PoemSummary(id: 2131, categoryId: 24, title: "غزل شمارهٔ ۲", urlSlug: "sh2"),
                        poetId: 2)
            }
            .libraryDestinations()
        }
    }
}

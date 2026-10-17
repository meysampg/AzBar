import SwiftUI

struct LibraryView: View {
    @Environment(\.contentRepository) private var content
    @State private var query = ""
    @State private var isSearchPresented = false

    var body: some View {
        Group {
            if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                poetList
            } else {
                SearchResultsView(query: query)
            }
        }
        .azScreenBackground()
        .navigationTitle("کتابخانه")
        .searchable(text: $query, isPresented: $isSearchPresented, prompt: "جستجوی شعر یا مصراع")
        .onChange(of: isSearchPresented) { _, presented in
            if presented { Task { await content.prewarmSearchIndex() } }
        }
    }

    private var poetList: some View {
        List {
            ForEach(content.catalog.enabledPoets) { entry in
                NavigationLink(value: LibraryRoute.poet(entry.id)) {
                    LibraryPoetRow(entry: entry)
                }
                .listRowBackground(Theme.Palette.card)
            }
        }
        .azList()
        .overlay {
            if content.catalog.enabledPoets.isEmpty {
                AzEmptyState("books.vertical", "شاعری در دسترس نیست")
            }
        }
    }
}

struct LibraryPoetRow: View {
    let entry: PoetCatalogEntry

    private var lifespan: String? {
        guard let birth = entry.birthYearHijri, let death = entry.deathYearHijri else { return nil }
        // Word joiners and a no-break space keep the years together when the line wraps.
        return "\(entry.fullName) · \(birth.fa)\u{2060}–\u{2060}\(death.fa)\u{00A0}ق"
    }

    var body: some View {
        HStack(alignment: .center, spacing: Theme.Spacing.m) {
            PoetMonogram(name: entry.name, size: 44)
            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text(verbatim: entry.name)
                    .font(.azHeadline)
                    .foregroundStyle(Theme.Palette.ink)
                Text(verbatim: lifespan ?? entry.fullName)
                    .font(.azMeta)
                    .foregroundStyle(Theme.Palette.inkSecondary)
            }
            Spacer(minLength: Theme.Spacing.s)
            availabilityChip
        }
        .padding(.vertical, Theme.Spacing.xs)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder private var availabilityChip: some View {
        if entry.isFullyBundled {
            AzChip("آفلاین", systemImage: "arrow.down.circle.fill", tone: .teal)
        } else if entry.isPartiallyBundled {
            AzChip("گزیدهٔ آفلاین", systemImage: "arrow.down.circle", tone: .gold)
                .accessibilityLabel("بخشی از اشعار بدون اینترنت در دسترس است")
        } else {
            AzChip("آنلاین", systemImage: "icloud", tone: .neutral)
        }
    }
}

#Preview {
    PreviewContainer {
        NavigationStack {
            LibraryView()
                .libraryDestinations()
        }
    }
}

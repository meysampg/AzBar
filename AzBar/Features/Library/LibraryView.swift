import SwiftUI

struct LibraryView: View {
    @Environment(\.contentRepository) private var content
    @State private var query = ""

    var body: some View {
        Group {
            if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                poetList
            } else {
                SearchResultsView(query: query)
            }
        }
        .navigationTitle("کتابخانه")
        .searchable(text: $query, prompt: "جستجوی شعر یا مصراع")
    }

    private var poetList: some View {
        List {
            ForEach(content.catalog.enabledPoets) { entry in
                NavigationLink(value: LibraryRoute.poet(entry.id)) {
                    LibraryPoetRow(entry: entry)
                }
            }
        }
        .overlay {
            if content.catalog.enabledPoets.isEmpty {
                ContentUnavailableView("شاعری در دسترس نیست", systemImage: "books.vertical")
            }
        }
    }
}

struct LibraryPoetRow: View {
    let entry: PoetCatalogEntry

    private var isOffline: Bool { entry.bundledPack != nil }

    private var lifespan: String? {
        guard let birth = entry.birthYearHijri, let death = entry.deathYearHijri else { return nil }
        return "\(birth.fa) – \(death.fa) ق"
    }

    var body: some View {
        HStack(alignment: .center, spacing: Theme.Spacing.m) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(verbatim: entry.name)
                    .font(.app(.headline))
                Text(verbatim: entry.fullName)
                    .font(.app(.subheadline))
                    .foregroundStyle(.secondary)
                if let lifespan {
                    Text(verbatim: lifespan)
                        .font(.app(.caption))
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer(minLength: Theme.Spacing.s)
            Label(isOffline ? "آفلاین" : "آنلاین",
                  systemImage: isOffline ? "arrow.down.circle" : "icloud")
                .font(.app(.caption))
                .foregroundStyle(isOffline ? Color.accentColor : Color.secondary)
                .padding(.horizontal, Theme.Spacing.s)
                .padding(.vertical, Theme.Spacing.xs)
                .background(.quaternary.opacity(0.5), in: .capsule)
        }
        .padding(.vertical, Theme.Spacing.xs)
        .accessibilityElement(children: .combine)
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

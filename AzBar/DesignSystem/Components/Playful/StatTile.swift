import SwiftUI

/// Small summary tile: symbol, value and caption in a white card.
struct StatTile: View {
    let title: LocalizedStringKey
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Image(systemName: systemImage)
                .font(.title2)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            Text(value)
                .font(.azNumber)
                .foregroundStyle(Theme.Palette.ink)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(title)
                .font(.app(.caption))
                .foregroundStyle(Theme.Palette.inkSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .azCard(padding: Theme.Spacing.m)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    HStack {
        StatTile(title: "امتیاز", value: 120.fa, systemImage: "bolt.fill", tint: Theme.Palette.gold)
        StatTile(title: "دقت", value: 90.fa, systemImage: "target", tint: Theme.Palette.success)
        StatTile(title: "بیت تازه", value: 3.fa, systemImage: "text.book.closed", tint: Theme.Palette.teal)
    }
    .padding(20)
    .azScreenBackground()
    .persianRoot()
}

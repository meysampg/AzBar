import SwiftUI

/// Small summary tile: symbol, value and title in a tinted rounded rectangle.
struct StatTile: View {
    let title: LocalizedStringKey
    let value: String
    let systemImage: String
    let tint: Color

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            Text(value)
                .font(.app(.title3, weight: .bold))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(title)
                .font(.app(.caption))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.m)
        .background(tint.opacity(colorScheme == .dark ? 0.2 : 0.12), in: RoundedRectangle(cornerRadius: Theme.Radius.card - 4, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.Radius.card - 4, style: .continuous)
                .strokeBorder(tint.opacity(0.3), lineWidth: 1.5)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    HStack {
        StatTile(title: "امتیاز", value: 120.fa, systemImage: "bolt.fill", tint: Theme.Playful.xp)
        StatTile(title: "درس", value: 8.fa, systemImage: "checkmark.seal.fill", tint: .green)
    }
    .padding()
    .persianRoot()
}

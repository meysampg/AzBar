// STUB (P-A): implement, keep signatures
import SwiftUI

/// Small summary tile: symbol, value and title in a tinted rounded rectangle.
struct StatTile: View {
    let title: LocalizedStringKey
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Image(systemName: systemImage).foregroundStyle(tint)
            Text(value).font(.app(.headline, weight: .bold))
            Text(title).font(.app(.caption))
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.m)
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: Theme.Radius.small))
    }
}

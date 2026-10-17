import SwiftUI

extension View {
    /// White continuous rounded card with a hairline border and the card shadow.
    func azCard(padding: CGFloat = Theme.Layout.cardPadding, fill: Color = Theme.Palette.card, bordered: Bool = true) -> some View {
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
        return self
            .padding(padding)
            .background(fill, in: shape)
            .overlay {
                if bordered { shape.strokeBorder(Theme.Palette.hairline, lineWidth: 1) }
            }
            .azShadow(Theme.Shadow.card)
    }

    /// Paper background for every screen.
    func azScreenBackground() -> some View {
        background { Theme.Palette.paper.ignoresSafeArea() }
    }

    /// Inset-grouped list on paper.
    func azList() -> some View {
        listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .azScreenBackground()
    }
}

#Preview {
    VStack(spacing: 16) {
        Text("کارت").frame(maxWidth: .infinity).azCard()
        Text("کارت طلایی").frame(maxWidth: .infinity).azCard(fill: Theme.Palette.goldSoft, bordered: false)
    }
    .padding(20)
    .azScreenBackground()
    .persianRoot()
}

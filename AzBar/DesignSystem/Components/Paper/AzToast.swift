import SwiftUI

/// White capsule toast with the elevated shadow. Apply the slide-in transition at the call site.
struct AzToast<Content: View>: View {
    @ViewBuilder var content: Content

    init(@ViewBuilder _ content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(.horizontal, Theme.Spacing.l)
            .padding(.vertical, Theme.Spacing.s)
            .background(Theme.Palette.card, in: .capsule)
            .overlay { Capsule().strokeBorder(Theme.Palette.hairline, lineWidth: 1) }
            .azShadow(Theme.Shadow.elevated)
    }
}

#Preview {
    AzToast {
        HStack {
            BadgeMedal(badge: .firstLesson, unlocked: true, size: 28)
            Text("دستاورد تازه: نخستین گام").font(.app(.subheadline, weight: .semibold))
        }
    }
    .padding()
    .azScreenBackground()
    .persianRoot()
}

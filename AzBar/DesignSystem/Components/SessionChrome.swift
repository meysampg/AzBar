import SwiftUI

// MARK: - Shared session chrome (used by Learn, Review and Fal)

/// Bottom bar for session screens: paper background with a hairline on top. No glass.
struct SessionActionBar<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: Theme.Spacing.s) {
            content
        }
        .padding(.horizontal, Theme.Layout.margin)
        .padding(.top, Theme.Spacing.m)
        .padding(.bottom, Theme.Spacing.s)
        .frame(maxWidth: Theme.Layout.sessionWidth)
        .frame(maxWidth: .infinity)
        .background(alignment: .top) {
            Theme.Palette.paper
                .overlay(alignment: .top) { Theme.Palette.hairline.frame(height: 1) }
                .ignoresSafeArea(edges: .bottom)
        }
    }
}

/// Full-width primary button.
struct SessionPrimaryButton: View {
    let title: LocalizedStringKey
    var systemImage: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            if let systemImage {
                Label(title, systemImage: systemImage)
            } else {
                Text(title)
            }
        }
        .buttonStyle(.azPrimary)
    }
}

/// Both mesras of a couplet as cloze rows, laid out like `CoupletView(.stacked)`.
struct ClozeCoupletView: View {
    let cloze: ClozeEngine
    let hiddenIds: Set<Int>
    var style: ClozeMesraView.Style = .blank

    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        if cloze.tokens.count > 1, sizeClass == .compact {
            VStack(spacing: Theme.Spacing.m) {
                ClozeMesraView(tokens: cloze.tokens[0], hiddenIds: hiddenIds, style: style, rowAlignment: .leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                ClozeMesraView(tokens: cloze.tokens[1], hiddenIds: hiddenIds, style: style, rowAlignment: .trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        } else {
            VStack(spacing: Theme.Spacing.m) {
                ForEach(Array(cloze.tokens.enumerated()), id: \.offset) { _, tokens in
                    ClozeMesraView(tokens: tokens, hiddenIds: hiddenIds, style: style)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

/// Dashed placeholder standing for the mesra/beyt the user must recall.
struct RecallPlaceholder: View {
    var label: String = "مصراع پنهان"

    @Environment(AppSettings.self) private var settings: AppSettings?

    var body: some View {
        let font = settings?.poemFont ?? .naskh
        RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
            .strokeBorder(Color(hex: 0xCFC3A8), style: StrokeStyle(lineWidth: 1.5, dash: [7, 5]))
            .frame(maxWidth: .infinity, minHeight: 96)
            .overlay {
                Text("؟")
                    .font(.poem(font, size: 34))
                    .foregroundStyle(Theme.Palette.sandDeep)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
    }
}

/// Wraps a couplet in the shared white card.
struct SessionCard<Content: View>: View {
    var dimmed = false
    @ViewBuilder var content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity)
            .azCard()
            .opacity(dimmed ? 0.55 : 1)
    }
}

/// A fully visible couplet inside a card.
struct RevealedCoupletCard: View {
    let couplet: Couplet
    var dimmed = false
    var showMeaning = false

    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        SessionCard(dimmed: dimmed) {
            CoupletView(couplet: couplet, layout: sizeClass == .compact ? .stacked : .sideBySide,
                        showMeaning: showMeaning)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        RevealedCoupletCard(couplet: PreviewFixtures.samplePoem.couplets[0], showMeaning: true)
        RecallPlaceholder()
        Spacer()
        SessionActionBar {
            Button("ادامه") {}.buttonStyle(.azPrimary)
            Button("نمی‌دانم") {}.buttonStyle(.azTertiary)
        }
    }
    .padding(.top, 20)
    .padding(.horizontal, 20)
    .azScreenBackground()
    .persianRoot()
}

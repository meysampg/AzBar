import SwiftUI

/// Poem title block with a collapsible "about this poem" card.
struct ReaderHeaderView: View {
    let poem: Poem
    let poetName: String

    @State private var isSummaryExpanded = false

    private var hasSummary: Bool { !(poem.summary ?? "").isEmpty }

    var body: some View {
        VStack(spacing: Theme.Spacing.m) {
            VStack(spacing: Theme.Spacing.xs) {
                Text(verbatim: poem.title)
                    .font(.app(.title2))
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                Text(verbatim: poem.fullTitle)
                    .font(.app(.footnote))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)

            if hasSummary, let summary = poem.summary {
                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                    Button {
                        withAnimation(.smooth(duration: 0.25)) { isSummaryExpanded.toggle() }
                    } label: {
                        HStack {
                            Label("دربارهٔ این شعر", systemImage: "info.circle")
                                .font(.app(.subheadline, weight: .medium))
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.footnote.weight(.semibold))
                                .rotationEffect(.degrees(isSummaryExpanded ? 180 : 0))
                        }
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityValue(isSummaryExpanded ? "باز" : "بسته")
                    .accessibilityHint("برای نمایش یا پنهان کردن توضیح بزنید")

                    if isSummaryExpanded {
                        Text(verbatim: summary)
                            .font(.app(.subheadline))
                            .foregroundStyle(.secondary)
                            .lineSpacing(4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(Theme.Spacing.l)
                .background(.background.secondary, in: .rect(cornerRadius: Theme.Radius.card))
            }
        }
    }
}

#Preview {
    ReaderHeaderView(poem: PreviewFixtures.samplePoem, poetName: "حافظ")
        .padding()
        .environment(\.layoutDirection, .rightToLeft)
}

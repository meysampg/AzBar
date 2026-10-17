import SwiftUI

enum CoupletLayout { case stacked, sideBySide }

struct CoupletView: View {
    let couplet: Couplet
    let layout: CoupletLayout
    var isHighlighted: Bool = false
    let showMeaning: Bool
    var transform: (String) -> String = { $0 }

    @Environment(AppSettings.self) private var settings: AppSettings?
    @State private var isMeaningExpanded = true

    init(couplet: Couplet, layout: CoupletLayout, isHighlighted: Bool = false, showMeaning: Bool,
         transform: @escaping (String) -> String = { $0 }) {
        self.couplet = couplet
        self.layout = layout
        self.isHighlighted = isHighlighted
        self.showMeaning = showMeaning
        self.transform = transform
    }

    private var font: PoemFont { settings?.poemFont ?? .naskh }
    private var size: CGFloat { CGFloat(settings?.poemFontSize ?? 22) }

    private var accessibilityText: String {
        if let second = couplet.secondMesra {
            return "مصراع اول: \(transform(couplet.firstMesra)). مصراع دوم: \(transform(second))"
        }
        return transform(couplet.firstMesra)
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.s) {
            verses
                .padding(.vertical, Theme.Spacing.m)
                .padding(.horizontal, Theme.Spacing.m)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(accessibilityText)
            if showMeaning, let summary = couplet.summary, !summary.isEmpty {
                meaning(summary)
            }
        }
        .padding(.horizontal, Theme.Spacing.s)
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.highlight, style: .continuous)
                .fill(Theme.Palette.tealSoft.opacity(isHighlighted ? 1 : 0))
        }
        .animation(.easeInOut(duration: 0.25), value: isHighlighted)
    }

    @ViewBuilder private var verses: some View {
        if couplet.kind == .beyt, let second = couplet.secondMesra {
            switch layout {
            case .stacked:
                VStack(spacing: 6) {
                    MesraText(text: transform(couplet.firstMesra), font: font, size: size, alignment: .leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    MesraText(text: transform(second), font: font, size: size, alignment: .trailing)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            case .sideBySide:
                HStack(spacing: 28) {
                    MesraText(text: transform(couplet.firstMesra), font: font, size: size)
                        .frame(maxWidth: .infinity)
                    MesraText(text: transform(second), font: font, size: size)
                        .frame(maxWidth: .infinity)
                }
            }
        } else if couplet.kind == .paragraph {
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                ForEach(couplet.verses) { verse in
                    Text(verbatim: transform(verse.text))
                        .font(.poem(font == .nastaliq ? .naskh : font, size: size * 0.85))
                        .foregroundStyle(Theme.Palette.ink)
                        .lineSpacing(size * 0.5)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        } else {
            VStack(spacing: 6) {
                ForEach(couplet.verses) { verse in
                    MesraText(text: transform(verse.text), font: font, size: size)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func meaning(_ summary: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { isMeaningExpanded.toggle() }
            } label: {
                Label("معنی", systemImage: isMeaningExpanded ? "chevron.up" : "chevron.down")
                    .font(.app(.footnote, weight: .medium))
            }
            .buttonStyle(.plain)
            .foregroundStyle(Theme.Palette.teal)
            .accessibilityLabel(isMeaningExpanded ? "پنهان کردن معنی" : "نمایش معنی")
            if isMeaningExpanded {
                Text(verbatim: summary)
                    .font(.azMeta)
                    .foregroundStyle(Theme.Palette.inkSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Theme.Spacing.m)
        .padding(.bottom, Theme.Spacing.m)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            ForEach(PreviewFixtures.samplePoem.couplets) { c in
                CoupletView(couplet: c, layout: .stacked, isHighlighted: c.index == 1, showMeaning: true)
            }
        }
        .padding()
    }
    .azScreenBackground()
    .persianRoot()
}

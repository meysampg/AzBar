import SwiftUI

/// One mesra rendered as wrapping word tokens. Hidden tokens keep their width (the real text is
/// drawn invisibly under a capsule), optionally showing a first-letter hint, and can be peeked
/// at by tapping.
struct ClozeMesraView: View {
    enum Style { case blank, hints }

    let tokens: [MesraToken]
    let hiddenIds: Set<Int>
    var style: Style = .blank
    var rowAlignment: HorizontalAlignment = .center
    /// How long a tapped word stays visible.
    var peekDuration: Duration = .milliseconds(1500)

    @Environment(AppSettings.self) private var settings: AppSettings?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var peeked: Set<Int> = []
    @State private var peekCount = 0

    private var font: PoemFont { settings?.poemFont ?? .naskh }
    private var size: CGFloat { CGFloat(settings?.poemFontSize ?? 22) }

    var body: some View {
        FlowLayout(
            horizontalSpacing: size * 0.28,
            verticalSpacing: font.lineSpacing(size) * 0.6,
            rowAlignment: rowAlignment
        ) {
            ForEach(tokens) { token in
                tokenView(token)
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: peekCount)
        .onChange(of: hiddenIds) { _, _ in peeked = [] }
    }

    @ViewBuilder
    private func tokenView(_ token: MesraToken) -> some View {
        let isHidden = hiddenIds.contains(token.id) && !peeked.contains(token.id)
        let isHiddenWord = hiddenIds.contains(token.id)
        if isHiddenWord {
            Button { peek(token) } label: { hiddenBody(token, concealed: isHidden) }
                .buttonStyle(.plain)
                .accessibilityLabel(isHidden ? "واژهٔ پنهان" : token.text)
                .accessibilityHint(isHidden ? "برای دیدن واژه دو بار ضربه بزنید" : "")
                .accessibilityAction(named: "نمایش واژه") { peek(token) }
        } else {
            Text(verbatim: token.text)
                .font(.poem(font, size: size))
                .padding(.vertical, font.verticalPadding(size))
        }
    }

    private func hiddenBody(_ token: MesraToken, concealed: Bool) -> some View {
        Text(verbatim: token.text)
            .font(.poem(font, size: size))
            .opacity(concealed ? 0 : 1)
            .padding(.vertical, font.verticalPadding(size))
            .padding(.horizontal, size * 0.15)
            .background {
                RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
                    .fill(.quaternary)
                    .opacity(concealed ? 1 : 0.35)
            }
            .overlay {
                if concealed, style == .hints {
                    Text(verbatim: ClozeEngine.firstLetterHint(token))
                        .font(.poem(font, size: size))
                        .foregroundStyle(.secondary)
                        .padding(.vertical, font.verticalPadding(size))
                }
            }
            .contentShape(.rect)
    }

    private func peek(_ token: MesraToken) {
        guard !peeked.contains(token.id) else { return }
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { _ = peeked.insert(token.id) }
        peekCount += 1
        let id = token.id
        Task {
            try? await Task.sleep(for: peekDuration)
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { _ = peeked.remove(id) }
        }
    }
}

#Preview("Blank") {
    let couplet = PreviewFixtures.samplePoem.couplets[1]
    let engine = ClozeEngine(poemId: 2130, couplet: couplet)
    return PreviewContainer {
      VStack(spacing: 12) {
        ForEach(Array(engine.tokens.enumerated()), id: \.offset) { _, tokens in
            ClozeMesraView(tokens: tokens, hiddenIds: engine.hiddenIds(level: 2))
        }
        ForEach(Array(engine.tokens.enumerated()), id: \.offset) { _, tokens in
            ClozeMesraView(tokens: tokens, hiddenIds: engine.hiddenIds(level: 3), style: .hints)
        }
      }
      .padding()
    }
}

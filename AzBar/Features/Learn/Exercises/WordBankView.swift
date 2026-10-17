import SwiftUI

/// Word-bank exercise: tap tiles from the bank to build the mesra in the answer row, tap an answer
/// tile to put it back. The first word lands at the leading (right) edge.
struct WordBankView: View {
    let exercise: WordBankExercise
    /// Ids of the tiles in the answer row, in answer order.
    @Binding var chosen: [Int]
    /// Non-nil once the answer has been checked.
    var result: ExerciseResult?

    @Environment(AppSettings.self) private var settings: AppSettings?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var namespace

    private var font: PoemFont { settings?.poemFont ?? .naskh }
    private var tiles: [Int: WordTile] { Dictionary(uniqueKeysWithValues: exercise.bank.map { ($0.id, $0) }) }
    private var isChecked: Bool { result != nil }

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            answerArea
            bankArea
        }
        .sensoryFeedback(.selection, trigger: chosen)
    }

    private var answerArea: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                Color.clear.frame(height: 46)
                Capsule().fill(Theme.Palette.hairline).frame(height: 2)
                Color.clear.frame(height: 50)
                Capsule().fill(Theme.Palette.hairline).frame(height: 2)
            }
            FlowLayout(horizontalSpacing: Theme.Spacing.s, verticalSpacing: Theme.Spacing.s, rowAlignment: .leading) {
                ForEach(Array(chosen.enumerated()), id: \.element) { position, id in
                    if let tile = tiles[id] {
                        Button { remove(id) } label: { label(tile) }
                            .buttonStyle(AzTileStyle(state: answerState(position)))
                            .matchedGeometryEffect(id: id, in: namespace)
                            .accessibilityHint(isChecked ? "" : "برای بازگرداندن ضربه بزنید")
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, minHeight: 104, alignment: .top)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("پاسخ شما")
    }

    private var bankArea: some View {
        FlowLayout(horizontalSpacing: Theme.Spacing.s, verticalSpacing: Theme.Spacing.s, rowAlignment: .center) {
            ForEach(exercise.bank) { tile in
                if chosen.contains(tile.id) {
                    Button {} label: { label(tile).opacity(0) }
                        .buttonStyle(AzTileStyle(state: .placeholder))
                        .disabled(true)
                        .accessibilityHidden(true)
                } else {
                    Button { add(tile.id) } label: { label(tile) }
                        .buttonStyle(AzTileStyle())
                        .matchedGeometryEffect(id: tile.id, in: namespace)
                        .accessibilityHint(isChecked ? "" : "برای افزودن به پاسخ ضربه بزنید")
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func label(_ tile: WordTile) -> some View {
        Text(verbatim: tile.text)
            .font(.poem(font, size: 20))
            .frame(minHeight: 28)
    }

    private func answerState(_ position: Int) -> AzTileStyle.TileState {
        guard let result else { return .normal }
        return result.wrongPositions.contains(position) ? .wrong : .correct
    }

    private func add(_ id: Int) {
        guard !isChecked, !chosen.contains(id) else { return }
        animate { chosen.append(id) }
    }

    private func remove(_ id: Int) {
        guard !isChecked else { return }
        animate { chosen.removeAll { $0 == id } }
    }

    private func animate(_ body: () -> Void) {
        if reduceMotion { body() } else { withAnimation(.snappy(duration: 0.25), body) }
    }
}

#Preview {
    PreviewContainer {
        WordBankPreview()
    }
}

private struct WordBankPreview: View {
    @State private var chosen: [Int] = []

    var body: some View {
        let poem = PreviewFixtures.samplePoem
        let index = poem.memorizableCouplets.first?.index ?? 0
        ScrollView {
            if let exercise = WordBankExercise.make(poem: poem, coupletIndex: index, mesraIndex: 0, distractorCount: 2) {
                WordBankView(exercise: exercise, chosen: $chosen, result: nil).padding()
            }
        }
    }
}

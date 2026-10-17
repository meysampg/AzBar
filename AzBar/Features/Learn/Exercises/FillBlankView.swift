import SwiftUI

/// Fill-the-blank exercise: a mesra with one dashed gap and a grid of option tiles.
struct FillBlankView: View {
    let exercise: FillBlankExercise
    /// A fully visible mesra shown above, for context (the first mesra when the blank is in the second).
    var contextMesra: String?
    @Binding var selected: Int?
    /// Non-nil once the answer has been checked.
    var result: ExerciseResult?

    @Environment(AppSettings.self) private var settings: AppSettings?

    private var font: PoemFont { settings?.poemFont ?? .naskh }
    private var size: CGFloat { CGFloat(settings?.poemFontSize ?? 22) }
    private var isChecked: Bool { result != nil }
    private var correctText: String { exercise.options[exercise.correctOptionIndex] }

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            SessionCard {
                VStack(spacing: Theme.Spacing.m) {
                    if let contextMesra {
                        MesraText(text: contextMesra, font: font, size: size)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    FlowLayout(horizontalSpacing: size * 0.28, verticalSpacing: font.lineSpacing(size) * 0.6,
                               rowAlignment: .center) {
                        ForEach(exercise.tokens) { token in
                            if token.id == exercise.blankTokenId {
                                blankSlot
                            } else {
                                Text(verbatim: token.text)
                                    .font(.poem(font, size: size))
                                    .padding(.vertical, font.verticalPadding(size))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Theme.Spacing.m), count: 2),
                      spacing: Theme.Spacing.m) {
                ForEach(Array(exercise.options.enumerated()), id: \.offset) { index, option in
                    Button {
                        guard !isChecked else { return }
                        selected = index
                    } label: {
                        Text(verbatim: option)
                            .font(.poem(font, size: 20))
                            .frame(maxWidth: .infinity, minHeight: 28)
                    }
                    .buttonStyle(ChunkyTileStyle(isSelected: selected == index && !isChecked, state: optionState(index)))
                    .accessibilityAddTraits(selected == index ? .isSelected : [])
                }
            }
            .sensoryFeedback(.selection, trigger: selected)
        }
    }

    private var blankSlot: some View {
        let shown: String? = isChecked ? correctText : selected.map { exercise.options[$0] }
        let tint: Color = {
            guard let result else { return .secondary }
            return result.isCorrect ? Theme.Playful.correct : Theme.Playful.wrong
        }()
        return Text(verbatim: correctText)
            .font(.poem(font, size: size))
            .opacity(0)
            .padding(.vertical, font.verticalPadding(size))
            .padding(.horizontal, size * 0.3)
            .overlay {
                if let shown {
                    Text(verbatim: shown)
                        .font(.poem(font, size: size))
                        .foregroundStyle(isChecked ? tint : Color.primary)
                }
            }
            .background {
                RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
                    .strokeBorder(tint.opacity(0.7), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(shown.map { "جای خالی: \($0)" } ?? "جای خالی")
    }

    private func optionState(_ index: Int) -> ChunkyTileStyle.TileState {
        guard isChecked else { return .normal }
        if index == exercise.correctOptionIndex { return .correct }
        if index == selected { return .wrong }
        return .normal
    }
}

#Preview {
    PreviewContainer {
        FillBlankPreview()
    }
}

private struct FillBlankPreview: View {
    @State private var selected: Int?

    var body: some View {
        let poem = PreviewFixtures.samplePoem
        let index = poem.memorizableCouplets.first?.index ?? 0
        ScrollView {
            if let exercise = FillBlankExercise.make(poem: poem, coupletIndex: index, mesraIndex: 1) {
                FillBlankView(exercise: exercise, contextMesra: poem.couplet(at: index)?.firstMesra,
                              selected: $selected, result: nil).padding()
            }
        }
    }
}

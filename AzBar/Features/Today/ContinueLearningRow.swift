import SwiftUI

struct ContinueLearningRow: View {
    let title: String
    let poetName: String
    let progress: PoemProgress
    let isComplete: Bool
    let onOpen: () -> Void

    private var learned: Int { max(0, progress.total - progress.notStarted) }

    var body: some View {
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                HStack(alignment: .firstTextBaseline) {
                    Text(verbatim: title).font(.app(.headline))
                    Spacer(minLength: Theme.Spacing.s)
                    Text(verbatim: poetName)
                        .font(.app(.subheadline))
                        .foregroundStyle(.secondary)
                }
                ProgressView(value: min(max(progress.fraction, 0), 1))
                    .accessibilityHidden(true)
                HStack {
                    Text("\(learned.fa) از \(progress.total.fa) بیت")
                    if isComplete {
                        Spacer()
                        Label("آموخته شد", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
                .font(.app(.caption))
                .foregroundStyle(.secondary)
            }
            .padding(.vertical, Theme.Spacing.xs)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title)، \(poetName)")
        .accessibilityValue("\(learned.fa) از \(progress.total.fa) بیت")
        .accessibilityHint(isComplete ? "برای دیدن شعر ضربه بزنید" : "برای ادامهٔ حفظ ضربه بزنید")
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    List {
        ContinueLearningRow(title: "غزل شمارهٔ ۱", poetName: "حافظ",
                            progress: PoemProgress(total: 7, notStarted: 4, learning: 2, young: 1, mature: 0),
                            isComplete: false, onOpen: {})
    }
    .environment(\.layoutDirection, .rightToLeft)
}

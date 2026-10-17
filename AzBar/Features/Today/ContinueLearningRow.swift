import SwiftUI

/// Content of a «در حال حفظ» row. The row itself is wrapped in a `NavigationLink` by the caller.
struct ContinueLearningRow: View {
    let title: String
    let poetName: String
    let progress: PoemProgress
    let isComplete: Bool
    /// 1-based current lesson and total lesson count; nil when unknown or finished.
    var nextLesson: (current: Int, total: Int)? = nil
    var crowns: Int = 0

    private var learned: Int { max(0, progress.total - progress.notStarted) }

    var body: some View {
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
                } else if let nextLesson {
                    Text("· درس بعدی: \(nextLesson.current.fa) از \(nextLesson.total.fa)")
                }
                if crowns > 0 {
                    Spacer()
                    Label("\(crowns.fa) تاج", systemImage: "crown.fill")
                        .foregroundStyle(Theme.Playful.gold)
                }
            }
            .font(.app(.caption))
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, Theme.Spacing.xs)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title)، \(poetName)")
        .accessibilityValue("\(learned.fa) از \(progress.total.fa) بیت")
        .accessibilityHint("مسیر یادگیری را باز می‌کند")
    }
}

#Preview {
    List {
        ContinueLearningRow(title: "غزل شمارهٔ ۱", poetName: "حافظ",
                            progress: PoemProgress(total: 7, notStarted: 4, learning: 2, young: 1, mature: 0),
                            isComplete: false, nextLesson: (2, 4), crowns: 1)
    }
    .persianRoot()
}

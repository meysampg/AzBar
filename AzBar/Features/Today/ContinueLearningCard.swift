import SwiftUI

/// Content of a «در حال حفظ» card. The caller wraps it in a `NavigationLink` with `.buttonStyle(.plain)`.
struct ContinueLearningCard: View {
    let title: String
    let poetName: String
    let progress: PoemProgress
    let isComplete: Bool
    /// 1-based current lesson and total lesson count; nil when unknown or finished.
    var nextLesson: (current: Int, total: Int)? = nil
    var crowns: Int = 0

    private var learned: Int { max(0, progress.total - progress.notStarted) }

    private var detail: String {
        var text = "\(learned.fa) از \(progress.total.fa) بیت"
        if !isComplete, let nextLesson {
            text += " · درس بعدی: \(nextLesson.current.fa) از \(nextLesson.total.fa)"
        }
        return text
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            HStack(alignment: .top, spacing: Theme.Spacing.s) {
                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                    Text(verbatim: title)
                        .font(.azHeadline)
                        .foregroundStyle(Theme.Palette.ink)
                    Text(verbatim: poetName)
                        .font(.azMeta)
                        .foregroundStyle(Theme.Palette.inkSecondary)
                }
                Spacer(minLength: Theme.Spacing.s)
                if isComplete {
                    AzChip("آموخته شد", systemImage: "checkmark", tone: .success)
                } else if crowns > 0 {
                    AzChip(crowns.fa, systemImage: "crown.fill", tone: .gold)
                        .accessibilityLabel("\(crowns.fa) تاج")
                }
            }
            AzProgressBar(value: min(max(progress.fraction, 0), 1), tint: Theme.Palette.teal)
                .accessibilityHidden(true)
            Text(detail)
                .font(.azCaption)
                .foregroundStyle(Theme.Palette.inkSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .azCard()
        .contentShape(.rect)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title)، \(poetName)")
        .accessibilityValue("\(learned.fa) از \(progress.total.fa) بیت")
        .accessibilityHint("مسیر یادگیری را باز می‌کند")
    }
}

#Preview {
    VStack(spacing: 12) {
        ContinueLearningCard(title: "غزل شمارهٔ ۱", poetName: "حافظ",
                             progress: PoemProgress(total: 7, notStarted: 4, learning: 2, young: 1, mature: 0),
                             isComplete: false, nextLesson: (2, 4), crowns: 1)
        ContinueLearningCard(title: "غزل شمارهٔ ۲", poetName: "حافظ",
                             progress: PoemProgress(total: 7, notStarted: 0, learning: 0, young: 0, mature: 7),
                             isComplete: true)
    }
    .padding(20)
    .azScreenBackground()
    .persianRoot()
}

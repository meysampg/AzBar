import SwiftUI

struct ReviewHomeView: View {
    @Environment(AppModel.self) private var model
    @Environment(ProgressStore.self) private var progress

    private var due: Int { progress.dueCount(until: ReviewQueueWindow.endOfToday()) }

    var body: some View {
        let plans = progress.activePlans()
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Layout.sectionGap) {
                if due > 0 {
                    dueCard
                } else {
                    emptyState
                }
                if !plans.isEmpty {
                    VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                        AzSectionHeader("در حال حفظ")
                        VStack(spacing: 0) {
                            ForEach(Array(plans.enumerated()), id: \.element.poemId) { index, plan in
                                if index > 0 { Divider().overlay(Theme.Palette.hairline) }
                                PlanRingRow(plan: plan)
                            }
                        }
                        .azCard(padding: 0)
                    }
                }
            }
            .padding(.horizontal, Theme.Layout.margin)
            .padding(.vertical, Theme.Spacing.l)
            .frame(maxWidth: Theme.Layout.readableWidth)
            .frame(maxWidth: .infinity)
        }
        .azScreenBackground()
        .navigationTitle("مرور")
    }

    private var dueCard: some View {
        VStack(spacing: Theme.Spacing.m) {
            Text(due.fa)
                .font(.azDisplay)
                .foregroundStyle(Theme.Palette.teal)
                .contentTransition(.numericText())
            Text("بیت برای مرور")
                .font(.azHeadline)
                .foregroundStyle(Theme.Palette.ink)
            let today = progress.todayActivity().reviews
            if today > 0 {
                Text("\(today.fa) بیت امروز")
                    .font(.azMeta)
                    .foregroundStyle(Theme.Palette.inkSecondary)
            }
            Button("شروع مرور") { model.isReviewPresented = true }
                .buttonStyle(.azPrimary)
        }
        .frame(maxWidth: .infinity)
        .azCard()
        .accessibilityElement(children: .contain)
    }

    private var emptyState: some View {
        AzEmptyState(
            "checkmark.seal", "مروری باقی نمانده",
            progress.nextDueDate().map { "مرور بعدی: \(relative($0))" }
                ?? "شعری را به فهرست حفظ بیفزایید تا مرور آغاز شود."
        )
        .frame(maxWidth: .infinity)
        .azCard()
    }

    private func relative(_ date: Date) -> String {
        let style = Date.RelativeFormatStyle(
            presentation: .named, unitsStyle: .wide,
            locale: Locale(identifier: "fa_IR"), calendar: Calendar(identifier: .persian)
        )
        return date.formatted(style)
    }
}

private struct PlanRingRow: View {
    let plan: MemorizationPlan
    @Environment(ProgressStore.self) private var progress
    @Environment(AppModel.self) private var model

    var body: some View {
        let p = progress.progress(poemId: plan.poemId, totalMemorizable: plan.memorizableCount)
        Button {
            model.startLearning(poemId: plan.poemId, poetId: plan.poetId)
        } label: {
            HStack(spacing: Theme.Spacing.m) {
                ProgressRing(value: p.fraction, showsPercent: true)
                    .frame(width: 44, height: 44)
                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                    Text(verbatim: plan.title).font(.azHeadline).foregroundStyle(Theme.Palette.ink)
                    Text(verbatim: plan.poetName).font(.azMeta).foregroundStyle(Theme.Palette.inkSecondary)
                }
                Spacer()
            }
            .padding(.horizontal, Theme.Layout.cardPadding)
            .padding(.vertical, Theme.Spacing.m)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("برای ادامهٔ حفظ ضربه بزنید")
    }
}

#Preview {
    PreviewContainer {
        NavigationStack { ReviewHomeView() }
    }
}

import SwiftUI

struct ReviewHomeView: View {
    @Environment(AppModel.self) private var model
    @Environment(ProgressStore.self) private var progress

    private var due: Int { progress.dueCount(until: ReviewQueueWindow.endOfToday()) }

    var body: some View {
        let plans = progress.activePlans()
        List {
            if due > 0 {
                Section { dueCard }
            } else {
                Section { emptyState }
                    .listRowBackground(Color.clear)
            }
            if !plans.isEmpty {
                Section {
                    ForEach(plans, id: \.poemId) { plan in
                        PlanRingRow(plan: plan)
                    }
                } header: {
                    Text("در حال حفظ").font(.app(.footnote))
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("مرور")
    }

    private var dueCard: some View {
        VStack(spacing: Theme.Spacing.m) {
            Text(due.fa)
                .font(.app(.largeTitle))
                .contentTransition(.numericText())
            Text("بیت برای مرور")
                .font(.app(.headline))
            let today = progress.todayActivity().reviews
            if today > 0 {
                Text("\(today.fa) بیت امروز")
                    .font(.app(.footnote))
                    .foregroundStyle(.secondary)
            }
            Button {
                model.isReviewPresented = true
            } label: {
                Text("شروع مرور")
                    .font(.app(.headline))
                    .frame(maxWidth: .infinity, minHeight: 36)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.s)
        .accessibilityElement(children: .contain)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("مروری باقی نمانده", systemImage: "checkmark.seal")
        } description: {
            if let next = progress.nextDueDate() {
                Text("مرور بعدی: \(relative(next))")
            } else {
                Text("شعری را به فهرست حفظ بیفزایید تا مرور آغاز شود.")
            }
        }
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
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: plan.title).font(.app(.headline))
                    Text(verbatim: plan.poetName).font(.app(.subheadline)).foregroundStyle(.secondary)
                }
                Spacer()
            }
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

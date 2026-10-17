import SwiftUI

/// End-of-session screen: result, XP, accuracy, streak, daily goal, level and new badges.
struct LessonCompleteView: View {
    let kind: LessonKind
    let passed: Bool
    let reward: SessionReward?
    let xp: Int
    let learnedCount: Int
    let isPoemComplete: Bool
    let hasNextLesson: Bool
    let onNext: () -> Void
    let onFinish: () -> Void

    @Environment(AppModel.self) private var app
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    @State private var confetti = 0
    @State private var isCelebrating = false
    @State private var celebrationsDone = false

    private var celebrations: [Celebration] { reward?.celebrations ?? [] }
    private var needsCelebration: Bool { !celebrations.isEmpty && !celebrationsDone }

    private var heading: String {
        switch kind {
        case .lesson: "درس تمام شد!"
        case .practice: "تمرین تمام شد!"
        case .challenge: passed ? "آزمون را گذراندید!" : "این بار نشد"
        }
    }

    private var icon: String {
        if kind == .challenge { return passed ? "trophy.fill" : "arrow.counterclockwise.circle.fill" }
        return "checkmark.seal.fill"
    }

    private var iconTint: Color {
        passed ? (kind == .challenge ? Theme.Playful.gold : Theme.Playful.correct) : Theme.Playful.wrong
    }

    private var levelUp: Int? {
        for case .levelUp(let level) in celebrations { return level }
        return nil
    }

    private var newBadges: [BadgeID] {
        celebrations.compactMap { if case .badge(let id) = $0 { id } else { nil } }
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    Image(systemName: icon)
                        .font(.system(size: 84))
                        .foregroundStyle(iconTint)
                        .symbolEffect(.bounce, options: .nonRepeating, value: reduceMotion ? false : appeared)
                        .accessibilityHidden(true)
                    titleBlock
                    tiles
                    statusCard
                    if levelUp != nil || !newBadges.isEmpty { rewardsRow }
                }
                .padding(.horizontal, Theme.Spacing.xl)
                .padding(.vertical, Theme.Spacing.xl)
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
            ConfettiView(trigger: confetti)
                .ignoresSafeArea()
            if isCelebrating {
                CelebrationSequenceView(celebrations: celebrations) {
                    withAnimation(reduceMotion ? nil : .smooth) {
                        celebrationsDone = true
                        isCelebrating = false
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
                .transition(.opacity)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !isCelebrating { actions }
        }
        .sensoryFeedback(passed ? .success : .warning, trigger: appeared)
        .task {
            appeared = true
            if passed { confetti += 1 }
            app.sounds.play(.lessonComplete)
        }
    }

    private var titleBlock: some View {
        VStack(spacing: Theme.Spacing.s) {
            Text(heading)
                .font(.app(.largeTitle))
                .accessibilityAddTraits(.isHeader)
            if kind == .challenge && !passed {
                Text("دوباره تلاش کنید")
                    .font(.app(.body))
                    .foregroundStyle(.secondary)
            }
            if learnedCount > 0 {
                Text("\(learnedCount.fa) بیت تازه از بر شد")
                    .font(.app(.title3))
            }
            if isPoemComplete {
                Text("همهٔ بیت‌های این شعر را آموختید")
                    .font(.app(.body))
                    .foregroundStyle(.secondary)
            } else if kind == .lesson && learnedCount > 0 {
                Text("بیت‌ها فردا در بخش مرور به شما یادآوری می‌شوند.")
                    .font(.app(.subheadline))
                    .foregroundStyle(.secondary)
            }
        }
        .multilineTextAlignment(.center)
    }

    private var tiles: some View {
        HStack(spacing: Theme.Spacing.m) {
            StatTile(title: "امتیاز", value: "+\(xp.fa)", systemImage: "bolt.fill", tint: Theme.Playful.xp)
            if let accuracy = reward?.accuracy {
                StatTile(title: "دقت", value: "\(Int((accuracy * 100).rounded()).fa)٪",
                         systemImage: "target", tint: Theme.Playful.correct)
            }
            if learnedCount > 0 {
                StatTile(title: "بیت تازه", value: learnedCount.fa, systemImage: "text.book.closed", tint: .blue)
            }
        }
    }

    private var statusCard: some View {
        let streak = app.progress.currentStreak()
        let goal = app.gamification.dailyGoal
        let today = app.gamification.todayXP
        let info = app.gamification.levelInfo
        return VStack(spacing: Theme.Spacing.m) {
            HStack(spacing: Theme.Spacing.l) {
                StreakFlame(streak: streak, isActiveToday: streak > 0, size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(streak.fa) روز پیاپی").font(.app(.headline))
                    Text("سطح \(info.level.fa) · \(LevelText.title(level: info.level))")
                        .font(.app(.footnote))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                VStack(spacing: 2) {
                    DailyGoalRing(xp: today, goal: goal, size: 60)
                    Text("هدف روزانه").font(.app(.caption)).foregroundStyle(.secondary)
                }
            }
            LessonProgressBar(value: info.fraction, tint: Theme.Playful.xp, height: 10)
                .accessibilityLabel("پیشرفت سطح")
        }
        .padding(Theme.Spacing.l)
        .background(.background.secondary, in: .rect(cornerRadius: Theme.Radius.card))
        .accessibilityElement(children: .contain)
    }

    private var rewardsRow: some View {
        VStack(spacing: Theme.Spacing.m) {
            if let level = levelUp {
                Label("به سطح \(level.fa) رسیدید", systemImage: "star.circle.fill")
                    .font(.app(.headline))
                    .foregroundStyle(Theme.Playful.gold)
            }
            if !newBadges.isEmpty {
                HStack(spacing: Theme.Spacing.l) {
                    ForEach(newBadges, id: \.self) { badge in
                        VStack(spacing: Theme.Spacing.xs) {
                            BadgeMedal(badge: badge, unlocked: true, size: 56)
                            Text(badge.title).font(.app(.caption))
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var actions: some View {
        SessionActionBar {
            VStack(spacing: Theme.Spacing.s) {
                if needsCelebration {
                    Button("ادامه") {
                        withAnimation(reduceMotion ? nil : .smooth) { isCelebrating = true }
                    }
                    .buttonStyle(.chunky(Theme.Playful.correct))
                } else {
                    if hasNextLesson {
                        Button("درس بعدی", action: onNext)
                            .buttonStyle(.chunky(Theme.Playful.correct))
                    }
                    Button("پایان", action: onFinish)
                        .buttonStyle(.chunky(hasNextLesson ? .blue : Theme.Playful.correct, filled: !hasNextLesson))
                }
            }
        }
    }
}

#Preview("Lesson") {
    PreviewContainer {
        LessonCompleteView(kind: .lesson, passed: true,
                           reward: SessionReward(xpEarned: 28, accuracy: 0.83, celebrations: []),
                           xp: 28, learnedCount: 2, isPoemComplete: false, hasNextLesson: true,
                           onNext: {}, onFinish: {})
    }
}

#Preview("Challenge failed") {
    PreviewContainer {
        LessonCompleteView(kind: .challenge, passed: false,
                           reward: SessionReward(xpEarned: 6, accuracy: 0.5, celebrations: []),
                           xp: 6, learnedCount: 0, isPoemComplete: false, hasNextLesson: false,
                           onNext: {}, onFinish: {})
    }
}

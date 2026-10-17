import SwiftUI

/// Pages through the celebrations (streak / daily goal / level up / badge) with a chunky «ادامه»;
/// confetti on level up and badge; plays the level-up sound; calls `onFinished` after the last page.
struct CelebrationSequenceView: View {
    let celebrations: [Celebration]
    let onFinished: () -> Void

    @Environment(AppModel.self) private var model: AppModel?
    @State private var index = 0
    @State private var confetti = 0

    private var current: Celebration? {
        celebrations.indices.contains(index) ? celebrations[index] : nil
    }

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            if let current {
                VStack(spacing: Theme.Spacing.xl) {
                    Spacer()
                    page(for: current)
                        .id(current.id)
                        .transition(.asymmetric(insertion: .scale(scale: 0.8).combined(with: .opacity), removal: .opacity))
                    Spacer()
                    Button(index == celebrations.count - 1 ? "ادامه" : "بعدی", action: advance)
                        .buttonStyle(.chunky(accent(for: current)))
                }
                .padding(Theme.Spacing.xl)
            }
            ConfettiView(trigger: confetti)
        }
        .animation(.spring(duration: 0.45, bounce: 0.3), value: index)
        .onAppear {
            if celebrations.isEmpty { onFinished() } else { entered() }
        }
    }

    private func advance() {
        if index + 1 < celebrations.count {
            index += 1
            entered()
        } else {
            onFinished()
        }
    }

    private func entered() {
        guard let current else { return }
        switch current {
        case .levelUp:
            model?.sounds.play(.levelUp)
            confetti += 1
        case .badge:
            model?.sounds.play(.lessonComplete)
            confetti += 1
        case .streak, .dailyGoal:
            break
        }
    }

    private func accent(for celebration: Celebration) -> Color {
        switch celebration {
        case .streak: Theme.Playful.xp
        case .dailyGoal: Theme.Playful.correct
        case .levelUp: .blue
        case .badge(let id): id.tint
        }
    }

    @ViewBuilder
    private func page(for celebration: Celebration) -> some View {
        switch celebration {
        case .streak(let days):
            content(title: "\(days.fa) روز پیاپی!", subtitle: "زنجیرهٔ تمرین شما ادامه دارد. فردا هم بیایید.") {
                StreakFlame(streak: days, isActiveToday: true, size: 110)
            }
        case .dailyGoal(let goal):
            content(title: "هدف روزانه کامل شد", subtitle: "\(goal.fa) امتیاز را امروز به دست آوردید.") {
                DailyGoalRing(xp: goal, goal: goal, size: 120)
            }
        case .levelUp(let level):
            content(title: "سطح \(level.fa)", subtitle: LevelText.title(level: level)) {
                ZStack {
                    Circle().fill(Color.blue.gradient).frame(width: 130, height: 130)
                    Text(level.fa).font(.app(.largeTitle, weight: .bold)).foregroundStyle(.white)
                }
                .accessibilityHidden(true)
            }
        case .badge(let id):
            content(title: "دستاورد تازه: \(id.title)", subtitle: id.detail) {
                BadgeMedal(badge: id, unlocked: true, size: 130)
            }
        }
    }

    private func content<Visual: View>(title: String, subtitle: String, @ViewBuilder visual: () -> Visual) -> some View {
        VStack(spacing: Theme.Spacing.l) {
            visual()
            Text(title)
                .font(.app(.title, weight: .bold))
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(.app(.body))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    CelebrationSequenceView(celebrations: [.streak(days: 7), .dailyGoal(goal: 20), .levelUp(level: 3), .badge(.firstLesson)]) {}
        .persianRoot()
}

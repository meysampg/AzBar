// STUB (P-A): implement, keep signatures
import SwiftUI

/// ProgressRing-like orange ring (lineWidth 9), center "\(xp.fa)/\(goal.fa)", checkmark once met.
struct DailyGoalRing: View {
    var xp: Int
    var goal: Int
    var size: CGFloat = 64

    var body: some View {
        ZStack {
            Circle().stroke(.quaternary, lineWidth: 9)
            Circle()
                .trim(from: 0, to: DailyGoal.progress(xp: xp, goal: goal))
                .stroke(Theme.Playful.xp, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(xp.fa)/\(goal.fa)").font(.app(.caption2))
        }
        .frame(width: size, height: size)
    }
}

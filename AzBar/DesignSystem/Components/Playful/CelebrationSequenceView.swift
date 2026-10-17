// STUB (P-A): implement, keep signatures
import SwiftUI

/// Pages through the celebrations (streak / daily goal / level up / badge) with a chunky «ادامه»;
/// confetti on level up and badge; plays the level-up sound; calls `onFinished` after the last page.
struct CelebrationSequenceView: View {
    let celebrations: [Celebration]
    let onFinished: () -> Void

    var body: some View {
        Button("ادامه", action: onFinished)
            .buttonStyle(.chunky())
            .padding()
    }
}

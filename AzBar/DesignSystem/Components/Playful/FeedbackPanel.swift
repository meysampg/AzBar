// STUB (P-A): implement, keep signatures
import SwiftUI

/// Bottom panel shown after a graded answer: green «آفرین!»-family title + «+۲ امتیاز», or red «نادرست» +
/// «پاسخ درست:» and the answer in the poem font. A chunky «ادامه» button unless an accessory is supplied
/// (then the accessory, e.g. a RatingBar, replaces it). Posts an AccessibilityNotification announcement.
struct FeedbackPanel<Accessory: View>: View {
    enum Kind: Equatable {
        case correct(message: String)
        case incorrect(answer: String)
    }

    let kind: Kind
    var xp: Int = 0
    let onContinue: () -> Void
    @ViewBuilder var accessory: Accessory

    init(kind: Kind, xp: Int = 0, onContinue: @escaping () -> Void, @ViewBuilder accessory: () -> Accessory) {
        self.kind = kind
        self.xp = xp
        self.onContinue = onContinue
        self.accessory = accessory()
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.m) {
            switch kind {
            case .correct(let message): Text(message)
            case .incorrect(let answer): Text(verbatim: answer)
            }
            accessory
        }
        .padding(Theme.Spacing.l)
    }
}

extension FeedbackPanel where Accessory == EmptyView {
    init(kind: Kind, xp: Int = 0, onContinue: @escaping () -> Void) {
        self.init(kind: kind, xp: xp, onContinue: onContinue) { EmptyView() }
    }
}

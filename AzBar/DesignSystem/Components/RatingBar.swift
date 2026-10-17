import SwiftUI

/// Four paper buttons (again / hard / good / easy) with the next interval under each title.
struct RatingBar: View {
    /// Preview of the scheduling outcome per rating; nil hides the intervals.
    var previews: [Rating: SchedulingResult]?
    var now: Date = .now
    /// Filled with the tone colour and captioned «پیشنهاد».
    var suggested: Rating? = nil
    var onRate: (Rating) -> Void

    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var tap: Tap?

    private struct Tap: Equatable {
        let rating: Rating
        let count: Int
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.s) {
            Text("چقدر خوب به یاد آوردید؟")
                .font(.app(.footnote, weight: .medium))
                .foregroundStyle(Theme.Palette.inkSecondary)
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: Theme.Spacing.s),
                               count: typeSize.isAccessibilitySize ? 2 : 4),
                spacing: Theme.Spacing.s
            ) {
                ForEach(Rating.allCases, id: \.self) { rating in
                    Button {
                        tap = Tap(rating: rating, count: (tap?.count ?? 0) + 1)
                        onRate(rating)
                    } label: {
                        VStack(spacing: 2) {
                            Text(Theme.title(for: rating))
                                .font(.app(.callout, weight: .semibold))
                            if let result = previews?[rating] {
                                Text(IntervalFormatter.short(result, from: now))
                                    .font(.app(.caption2))
                            }
                            if rating == suggested {
                                Text("پیشنهاد")
                                    .font(.app(.caption2, weight: .bold))
                            }
                        }
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity, minHeight: 52)
                    }
                    .buttonStyle(AzRatingButtonStyle(rating: rating, prominent: rating == suggested))
                    .accessibilityLabel(label(for: rating))
                }
            }
        }
        .sensoryFeedback(trigger: tap) { _, new in
            switch new?.rating {
            case .good, .easy: .success
            case .again: .warning
            case .hard: .impact(weight: .light)
            case nil: nil
            }
        }
    }

    private func label(for rating: Rating) -> String {
        let title = Theme.title(for: rating)
        var text = title
        if let result = previews?[rating] {
            text = "\(title)، مرور بعدی \(IntervalFormatter.short(result, from: now)) دیگر"
        }
        return rating == suggested ? text + "، پیشنهادی" : text
    }
}

#Preview {
    let scheduler = FSRSScheduler()
    let card = FSRSCard.new(now: .now)
    RatingBar(previews: scheduler.preview(card, now: .now), suggested: .good) { _ in }
        .padding()
        .azScreenBackground()
        .persianRoot()
}

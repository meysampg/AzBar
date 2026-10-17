import SwiftUI

@MainActor @Observable
final class FalModel {
    enum Phase: Equatable {
        case niyyat
        case opening
        case result(Poem)
        case failed
    }

    private(set) var phase: Phase = .niyyat
    /// Incremented for every confirmed niyyat; drives the view's `.task(id:)`.
    private(set) var requestId = 0

    private static let minimumOpeningDuration: Duration = .milliseconds(1200)

    func confirmNiyyat() {
        guard phase == .niyyat || phase == .failed else { return }
        phase = .opening
        requestId += 1
    }

    func reset() {
        phase = .niyyat
    }

    /// Fetches a random ghazal, keeping the opening animation on screen for at least 1.2 s.
    func open(content: ContentRepository) async {
        guard phase == .opening else { return }
        let poetId = content.catalog.enabledPoets.first { $0.falCategoryId != nil }?.id ?? 2
        let clock = ContinuousClock()
        let start = clock.now
        do {
            let poem = try await content.randomFalPoem(poetId: poetId)
            let remaining = Self.minimumOpeningDuration - (clock.now - start)
            if remaining > .zero { try await Task.sleep(for: remaining) }
            phase = .result(poem)
        } catch is CancellationError {
            return
        } catch {
            phase = .failed
        }
    }
}

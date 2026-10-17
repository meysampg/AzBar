import SwiftUI

@MainActor @Observable
final class ReaderModel {
    enum Phase { case loading, loaded, failed }

    let poemId: PoemID
    let poetId: PoetID

    private(set) var phase: Phase = .loading
    private(set) var poem: Poem?
    private(set) var poetName = ""
    private(set) var selectedRecitation: Recitation?
    /// For each offset into `poem.orderedVerses`, the index of the couplet containing it.
    private var verseToCouplet: [Int] = []

    init(poemId: PoemID, poetId: PoetID) {
        self.poemId = poemId
        self.poetId = poetId
    }

    func load(content: ContentRepository, preferredReciter: String?) async {
        if poem != nil { return }
        phase = .loading
        poetName = content.catalog.entry(poetId)?.name ?? ""
        do {
            let loaded = try await content.poem(poemId, poetId: poetId)
            var coupletByVerse: [Int: Int] = [:]
            for couplet in loaded.couplets {
                for verse in couplet.verses { coupletByVerse[verse.id] = couplet.index }
            }
            verseToCouplet = loaded.orderedVerses.map { coupletByVerse[$0.id] ?? -1 }
            selectedRecitation = RecitationPicker.preferred(loaded.recitations, artist: preferredReciter)
            poem = loaded
            phase = .loaded
        } catch {
            if !Task.isCancelled { phase = .failed }
        }
    }

    func coupletIndex(forVerseOffset offset: Int) -> Int? {
        guard verseToCouplet.indices.contains(offset), verseToCouplet[offset] >= 0 else { return nil }
        return verseToCouplet[offset]
    }

    // MARK: Audio

    private func isLoaded(in audio: AudioPlayerService) -> Bool {
        guard let poem, let selectedRecitation else { return false }
        if case .failed = audio.status { return false }
        return audio.poemId == poem.id && audio.recitation?.id == selectedRecitation.id
    }

    func togglePlayback(audio: AudioPlayerService) async {
        guard let poem, let selectedRecitation else { return }
        if isLoaded(in: audio) {
            audio.toggle()
            return
        }
        await audio.load(poem: poem, recitation: selectedRecitation, autoplay: true)
    }

    func select(_ recitation: Recitation, audio: AudioPlayerService) async {
        guard let poem else { return }
        let wasPlaying = audio.poemId == poem.id && audio.isPlaying
        let wasLoaded = audio.poemId == poem.id
        selectedRecitation = recitation
        guard wasLoaded else { return }
        await audio.load(poem: poem, recitation: recitation, autoplay: wasPlaying)
    }

    func playCouplet(_ index: Int, audio: AudioPlayerService) async {
        guard let poem, let selectedRecitation else { return }
        if !isLoaded(in: audio) {
            await audio.load(poem: poem, recitation: selectedRecitation)
        }
        await audio.playCouplet(index, in: poem)
    }

    /// Tap-to-seek: only while this poem is actively playing.
    func seekIfPlaying(toCouplet index: Int, audio: AudioPlayerService) {
        guard let poem, audio.poemId == poem.id, audio.status == .playing else { return }
        audio.seek(toCouplet: index, in: poem)
    }
}

import Foundation

/// Raw Ganjoor API shapes (only the fields the app needs). Everything is optional-tolerant.

public struct GanjoorPoetDTO: Decodable, Sendable {
    public var id: Int
    public var name: String?
    public var nickname: String?
    public var description: String?
    public var fullUrl: String?
    public var rootCatId: Int?
    public var birthYearInLHijri: Int?
    public var deathYearInLHijri: Int?
}

public struct GanjoorPoemSummaryDTO: Decodable, Sendable {
    public var id: Int
    public var title: String?
    public var urlSlug: String?
    public var excerpt: String?
}

public struct GanjoorCatDTO: Decodable, Sendable {
    public var id: Int
    public var title: String?
    public var urlSlug: String?
    public var fullUrl: String?
    public var ancestors: [GanjoorCatDTO]?
    public var children: [GanjoorCatDTO]?
    public var poems: [GanjoorPoemSummaryDTO]?
}

/// Response of `/poet/{id}` and `/cat/{id}` and the `category` field of a poem.
public struct GanjoorCatWithPoetDTO: Decodable, Sendable {
    public var poet: GanjoorPoetDTO?
    public var cat: GanjoorCatDTO?
}

public struct GanjoorVerseDTO: Decodable, Sendable {
    public var id: Int
    public var vOrder: Int
    public var coupletIndex: Int?
    public var versePosition: Int?
    public var text: String?
    public var coupletSummary: String?

    public init(id: Int, vOrder: Int, coupletIndex: Int?, versePosition: Int?, text: String?, coupletSummary: String? = nil) {
        self.id = id
        self.vOrder = vOrder
        self.coupletIndex = coupletIndex
        self.versePosition = versePosition
        self.text = text
        self.coupletSummary = coupletSummary
    }
}

public struct GanjoorRecitationDTO: Decodable, Sendable {
    public var id: Int
    public var audioArtist: String?
    public var mp3Url: String?
    public var xmlText: String?
    public var audioOrder: Int?
    public var recitationType: Int?
    public var inSyncWithText: Bool?

    public init(id: Int, audioArtist: String?, mp3Url: String?, xmlText: String?, audioOrder: Int?,
                recitationType: Int?, inSyncWithText: Bool?) {
        self.id = id
        self.audioArtist = audioArtist
        self.mp3Url = mp3Url
        self.xmlText = xmlText
        self.audioOrder = audioOrder
        self.recitationType = recitationType
        self.inSyncWithText = inSyncWithText
    }
}

public struct GanjoorPoemDTO: Decodable, Sendable {
    public var id: Int
    public var title: String?
    public var fullTitle: String?
    public var urlSlug: String?
    public var fullUrl: String?
    public var poemSummary: String?
    public var category: GanjoorCatWithPoetDTO?
    public var verses: [GanjoorVerseDTO]?
    public var recitations: [GanjoorRecitationDTO]?
}

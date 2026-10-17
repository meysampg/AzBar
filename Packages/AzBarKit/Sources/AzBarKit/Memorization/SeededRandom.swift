import Foundation

/// FNV-1a 64-bit hash (stable across processes, unlike `Hasher`).
public enum FNV1a64 {
    public static func hash(_ string: String) -> UInt64 {
        var h: UInt64 = 0xcbf29ce484222325
        for b in string.utf8 {
            h ^= UInt64(b)
            h = h &* 0x100000001b3
        }
        return h
    }
}

/// SplitMix64 deterministic generator.
public struct SplitMix64: RandomNumberGenerator, Sendable {
    private var state: UInt64

    public init(seed: UInt64) { state = seed }

    public mutating func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

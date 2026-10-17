#!/usr/bin/env swift
// Synthesizes the short feedback sounds into AzBar/Resources/Sounds/.
// Run from the repo root: swift Tools/make_sounds.swift
import Foundation

let sampleRate = 22_050.0

struct Note {
    var freq: Double
    var start: Double
    var dur: Double
    var tau: Double
    var partials: [(mult: Double, gain: Double)] = [(1, 1), (2, 0.35), (3, 0.1)]
    var bend: Double = 0          // total relative pitch change over the note
    var vibratoHz: Double = 0
    var vibratoDepth: Double = 0
    var gain: Double = 1
}

func render(_ notes: [Note], length: Double) -> [Int16] {
    let total = Int(length * sampleRate)
    var buf = [Double](repeating: 0, count: total)
    for n in notes {
        let begin = Int(n.start * sampleRate)
        let count = Int(n.dur * sampleRate)
        var phase = 0.0
        for i in 0..<count where begin + i < total {
            let t = Double(i) / sampleRate
            let attack = min(1, t / 0.005)
            let env = attack * exp(-t / n.tau)
            var f = n.freq * (1 + n.bend * t / n.dur)
            if n.vibratoHz > 0 { f *= 1 + n.vibratoDepth * sin(2 * .pi * n.vibratoHz * t) }
            phase += 2 * .pi * f / sampleRate
            var s = 0.0
            for p in n.partials { s += p.gain * sin(phase * p.mult) }
            buf[begin + i] += s * env * n.gain
        }
    }
    let peak = max(buf.map { abs($0) }.max() ?? 1, 1e-9)
    let scale = 0.8 / peak
    let fade = Int(0.010 * sampleRate)
    return buf.enumerated().map { idx, v in
        var x = v * scale
        let remaining = total - idx
        if remaining < fade { x *= Double(remaining) / Double(fade) }
        return Int16(max(-1, min(1, x)) * 32_767)
    }
}

func wav(_ samples: [Int16]) -> Data {
    var d = Data()
    func u32(_ v: UInt32) { var x = v.littleEndian; d.append(Data(bytes: &x, count: 4)) }
    func u16(_ v: UInt16) { var x = v.littleEndian; d.append(Data(bytes: &x, count: 2)) }
    let dataSize = UInt32(samples.count * 2)
    d.append("RIFF".data(using: .ascii)!); u32(36 + dataSize)
    d.append("WAVEfmt ".data(using: .ascii)!); u32(16); u16(1); u16(1)
    u32(UInt32(sampleRate)); u32(UInt32(sampleRate) * 2); u16(2); u16(16)
    d.append("data".data(using: .ascii)!); u32(dataSize)
    for s in samples { u16(UInt16(bitPattern: s)) }
    return d
}

let wrongPartials: [(mult: Double, gain: Double)] = [(1, 1), (3, 0.33), (5, 0.2)]
let sounds: [String: ([Note], Double)] = [
    "sfx-correct": ([
        Note(freq: 1046.5, start: 0, dur: 0.12, tau: 0.09),
        Note(freq: 1318.5, start: 0.09, dur: 0.25, tau: 0.15),
    ], 0.35),
    "sfx-wrong": ([
        Note(freq: 220, start: 0, dur: 0.14, tau: 0.12, partials: wrongPartials, bend: -0.03, gain: 0.6),
        Note(freq: 174.61, start: 0.12, dur: 0.22, tau: 0.12, partials: wrongPartials, bend: -0.03, gain: 0.6),
    ], 0.36),
    "sfx-lesson-complete": ([
        Note(freq: 523.25, start: 0, dur: 0.18, tau: 0.12),
        Note(freq: 659.25, start: 0.1, dur: 0.18, tau: 0.12),
        Note(freq: 783.99, start: 0.2, dur: 0.18, tau: 0.12),
        Note(freq: 783.99, start: 0.3, dur: 0.6, tau: 0.35),
        Note(freq: 1046.5, start: 0.3, dur: 0.6, tau: 0.35),
        Note(freq: 1318.5, start: 0.3, dur: 0.6, tau: 0.35),
    ], 0.95),
    "sfx-level-up": ([
        Note(freq: 392, start: 0, dur: 0.12, tau: 0.08),
        Note(freq: 523.25, start: 0.07, dur: 0.12, tau: 0.08),
        Note(freq: 659.25, start: 0.14, dur: 0.12, tau: 0.08),
        Note(freq: 783.99, start: 0.21, dur: 0.12, tau: 0.08),
        Note(freq: 1046.5, start: 0.28, dur: 0.12, tau: 0.08),
        Note(freq: 1046.5, start: 0.38, dur: 0.7, tau: 0.4, vibratoHz: 6, vibratoDepth: 0.004),
        Note(freq: 1567.98, start: 0.38, dur: 0.7, tau: 0.4, vibratoHz: 6, vibratoDepth: 0.004),
    ], 1.1),
]

let outDir = URL(fileURLWithPath: "AzBar/Resources/Sounds", isDirectory: true)
try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)
for (name, spec) in sounds {
    let url = outDir.appendingPathComponent(name + ".wav")
    try wav(render(spec.0, length: spec.1)).write(to: url)
    print("wrote \(url.path)")
}

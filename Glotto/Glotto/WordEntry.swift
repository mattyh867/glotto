//
//  WordEntry.swift
//  Glotto
//
//  Created by Matthew Hughes on 18/08/2026.
//

import Foundation

/// A worked example sentence for a word entry.
struct WordExample: Codable {
    let text: String
    let translation: String
}

/// A single word-of-the-day entry, matching the schema produced by select_words.py
/// (as seen in th.json).
struct WordEntry: Codable {
    let word: String
    let partOfSpeech: String
    let romanization: String
    let glossShort: String
    let example: WordExample
    let sourceUrl: String
    let frequencyRank: Int
}

/// Loads and caches th.json, and resolves "today's word" deterministically.
enum WordStore {

    /// Loads th.json from the target's bundle.
    /// If you're using an App Group to share the file between the app and widget,
    /// swap this out for a FileManager read from the shared container instead.
    static func loadWords() -> [WordEntry] {
        guard let url = Bundle.main.url(forResource: "th", withExtension: "json") else {
            assertionFailure("th.json not found in bundle — check target membership.")
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([WordEntry].self, from: data)
        } catch {
            assertionFailure("Failed to decode words.json: \(error)")
            return []
        }
    }

    /// Deterministic date-based selection: dayOfYear % array length.
    static func word(for date: Date, in words: [WordEntry]) -> WordEntry? {
        guard !words.isEmpty else { return nil }
        let calendar = Calendar(identifier: .gregorian)
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let index = (dayOfYear - 1) % words.count // -1 so Jan 1 maps to index 0
        return words[index]
    }
}

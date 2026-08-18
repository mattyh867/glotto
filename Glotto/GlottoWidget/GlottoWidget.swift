//
//  GlottoWidget.swift
//  Glotto
//
//  Created by Matthew Hughes on 18/08/2026.
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct WordTimelineEntry: TimelineEntry {
    let date: Date
    let word: WordEntry?
}

// MARK: - Timeline Provider

struct WordTimelineProvider: TimelineProvider {

    // Placeholder shown briefly while the widget first loads (e.g. in the widget gallery)
    func placeholder(in context: Context) -> WordTimelineEntry {
        WordTimelineEntry(date: Date(), word: Self.placeholderWord)
    }

    static let placeholderWord = WordEntry(
        word: "อะไร",
        partOfSpeech: "pron",
        romanization: "à-rai",
        glossShort: "what?",
        example: WordExample(text: "อะไรนะ?", translation: "What? What was that? Pardon?"),
        sourceUrl: "https://en.wiktionary.org/wiki/อะไร#Thai",
        frequencyRank: 8
    )

    // Snapshot shown in the widget gallery/preview
    func getSnapshot(in context: Context, completion: @escaping (WordTimelineEntry) -> Void) {
        let words = WordStore.loadWords()
        let word = WordStore.word(for: Date(), in: words)
        completion(WordTimelineEntry(date: Date(), word: word))
    }

    // Actual timeline used on-device
    func getTimeline(in context: Context, completion: @escaping (Timeline<WordTimelineEntry>) -> Void) {
        let words = WordStore.loadWords()
        let now = Date()
        let calendar = Calendar(identifier: .gregorian)

        let entry = WordTimelineEntry(date: now, word: WordStore.word(for: now, in: words))

        // Refresh at the next midnight so the widget picks up the next day's word.
        let startOfTomorrow = calendar.nextDate(
            after: now,
            matching: DateComponents(hour: 0, minute: 0, second: 0),
            matchingPolicy: .nextTime
        ) ?? now.addingTimeInterval(86400)

        let timeline = Timeline(entries: [entry], policy: .after(startOfTomorrow))
        completion(timeline)
    }
}

// MARK: - Views

struct GlottoWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: WordTimelineProvider.Entry

    var body: some View {
        switch family {
        case .accessoryRectangular:
            RectangularWordView(word: entry.word)
        case .accessoryInline:
            InlineWordView(word: entry.word)
        default:
            SystemWordView(word: entry.word, family: family)
        }
    }
}

struct RectangularWordView: View {
    let word: WordEntry?

    var body: some View {
        if let word {
            VStack(alignment: .leading, spacing: 2) {
                Text(word.word)
                    .font(.headline)
                    .lineLimit(1)
                Text(word.romanization)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(word.glossShort)
                    .font(.caption)
                    .lineLimit(1)
            }
            .containerBackground(.fill.tertiary, for: .widget)
        } else {
            Text("No word available")
                .font(.caption)
                .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}

/// Home Screen families (small/medium/large) — more room than the lock screen,
/// so medium and up also show the example sentence.
struct SystemWordView: View {
    let word: WordEntry?
    let family: WidgetFamily

    var body: some View {
        if let word {
            VStack(alignment: .leading, spacing: 4) {
                Text(word.word)
                    .font(.title2)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text(word.romanization)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(word.glossShort)
                    .font(.subheadline)
                    .lineLimit(2)

                if family != .systemSmall {
                    Spacer(minLength: 4)
                    Text(word.example.text)
                        .font(.caption)
                        .lineLimit(2)
                    Text(word.example.translation)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .containerBackground(.fill.tertiary, for: .widget)
        } else {
            Text("No word available")
                .font(.caption)
                .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}

struct InlineWordView: View {
    let word: WordEntry?

    var body: some View {
        if let word {
            // accessoryInline is a single line of text/icon, very constrained
            Text("\(word.word) · \(word.glossShort)")
        } else {
            Text("No word today")
        }
    }
}

// MARK: - Widget Configuration

struct GlottoWidget: Widget {
    let kind: String = "GlottoWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WordTimelineProvider()) { entry in
            GlottoWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Word of the Day")
        .description("A daily Thai word with its English meaning.")
        .supportedFamilies([
            .systemSmall, .systemMedium,   // Home Screen
            .accessoryRectangular, .accessoryInline // Lock Screen
        ])
    }
}

// MARK: - Previews

#Preview(as: .accessoryRectangular) {
    GlottoWidget()
} timeline: {
    WordTimelineEntry(date: .now, word: WordTimelineProvider.placeholderWord)
}

#Preview(as: .accessoryInline) {
    GlottoWidget()
} timeline: {
    WordTimelineEntry(date: .now, word: WordTimelineProvider.placeholderWord)
}

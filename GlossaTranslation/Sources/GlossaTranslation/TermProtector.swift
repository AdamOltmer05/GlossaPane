import Foundation

/// Helps reuse earlier translations of names and terms (FR12).
/// Before sending, known terms are wrapped in a "notranslate" tag so the service
/// leaves them alone. After translating, each tag is swapped for the earlier translation.
enum TermProtector {
    static let openTag = "<span class=\"notranslate\">"
    static let closeTag = "</span>"

    struct Protected: Equatable {
        let html: String
        let terms: [CacheEntry]   // in the order they appear in the text
    }

    static func escape(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    static func unescape(_ text: String) -> String {
        text.replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&#x27;", with: "'")
            .replacingOccurrences(of: "&amp;", with: "&")
    }

    static func protect(_ text: String, using candidates: [CacheEntry]) -> Protected {
        // Longest terms first, so a full name wins over a shorter name inside it.
        let sorted = candidates.sorted { $0.source.count > $1.source.count }
        var matches: [(range: Range<String.Index>, entry: CacheEntry)] = []

        for entry in sorted {
            guard !entry.source.isEmpty else { continue }
            var searchStart = text.startIndex
            while let found = text.range(of: entry.source, range: searchStart..<text.endIndex) {
                let overlaps = matches.contains { $0.range.overlaps(found) }
                if !overlaps {
                    matches.append((range: found, entry: entry))
                }
                searchStart = found.upperBound
            }
        }
        matches.sort { $0.range.lowerBound < $1.range.lowerBound }

        var html = ""
        var cursor = text.startIndex
        for match in matches {
            html += escape(String(text[cursor..<match.range.lowerBound]))
            html += openTag + escape(match.entry.source) + closeTag
            cursor = match.range.upperBound
        }
        html += escape(String(text[cursor...]))
        return Protected(html: html, terms: matches.map { $0.entry })
    }

    /// Turns the translated HTML back into plain text, using the earlier
    /// translation for each protected term. If the service changed the tags in
    /// a way we can't match, we just remove the tags and keep its text.
    static func restore(_ translatedHTML: String, terms: [CacheEntry]) -> String {
        guard !terms.isEmpty else { return unescape(translatedHTML) }

        let pattern = "<span class=\"notranslate\">.*?</span>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
            return stripTags(translatedHTML)
        }
        let ns = translatedHTML as NSString
        let found = regex.matches(in: translatedHTML, range: NSRange(location: 0, length: ns.length))
        guard found.count == terms.count else {
            return stripTags(translatedHTML)
        }

        var output = ""
        var last = 0
        for (index, match) in found.enumerated() {
            let before = ns.substring(with: NSRange(location: last, length: match.range.location - last))
            output += unescape(before)
            output += terms[index].translation
            last = match.range.location + match.range.length
        }
        output += unescape(ns.substring(from: last))
        return output
    }

    static func stripTags(_ html: String) -> String {
        let withoutTags = html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        return unescape(withoutTags)
    }
}

import Foundation

public struct CacheEntry: Equatable, Sendable {
    public let source: String
    public let translation: String

    public init(source: String, translation: String) {
        self.source = source
        self.translation = translation
    }
}

/// Remembers the most recent translations so names and repeated terms stay
/// consistent (FR12). It only lives in memory on the user's computer (FR15).
public actor ContextCache {
    public let capacity: Int
    private var entries: [CacheEntry] = []   // oldest first

    public init(capacity: Int = 50) {
        self.capacity = max(1, capacity)
    }

    public var count: Int { entries.count }
    public var allEntries: [CacheEntry] { entries }

    /// Returns the earlier translation of this exact text, if we have one.
    public func lookup(_ source: String) -> String? {
        entries.first(where: { $0.source == source })?.translation
    }

    /// Saves a translation. If the cache is over capacity, the oldest entry goes (FR15).
    public func record(source: String, translation: String) {
        entries.removeAll(where: { $0.source == source })
        entries.append(CacheEntry(source: source, translation: translation))
        if entries.count > capacity {
            entries.removeFirst(entries.count - capacity)
        }
    }

    /// Empties the cache (FR15).
    public func clear() {
        entries.removeAll()
    }

    /// Short cached entries, like character names, that appear inside `text`.
    /// Long lines are not treated as terms.
    public func terms(in text: String, minLength: Int = 2, maxLength: Int = 30) -> [CacheEntry] {
        entries.filter { entry in
            entry.source.count >= minLength
                && entry.source.count <= maxLength
                && entry.source != text
                && text.contains(entry.source)
        }
    }
}

import Foundation

/// The translation step. It takes recognized text from the capture and OCR step,
/// translates it, and returns the results with their original positions.
public actor Translator {
    private let service: TranslationService
    public let cache: ContextCache
    private var currentLanguage: String?

    public init(service: TranslationService, cache: ContextCache = ContextCache()) {
        self.service = service
        self.cache = cache
    }

    public func translate(_ request: TranslationRequest) async throws -> TranslationOutcome {
        // FR15: a new target language means the old context no longer applies.
        if let current = currentLanguage, current != request.targetLanguage {
            await cache.clear()
        }
        currentLanguage = request.targetLanguage

        // FR10: reject lines that have no text.
        var rejected: [UUID] = []
        var valid: [(item: RecognizedItem, text: String)] = []
        for item in request.items {
            let text = item.text.trimmingCharacters(in: .whitespacesAndNewlines)
            if text.isEmpty {
                rejected.append(item.id)
            } else {
                valid.append((item: item, text: text))
            }
        }

        // FR12: reuse the earlier translation for lines we have already seen,
        // and protect known names inside new lines.
        var resultsByID: [UUID: TranslatedItem] = [:]
        var pending: [(item: RecognizedItem, text: String, protected: TermProtector.Protected)] = []
        for entry in valid {
            if let cached = await cache.lookup(entry.text) {
                resultsByID[entry.item.id] = TranslatedItem(
                    id: entry.item.id,
                    originalText: entry.text,
                    translatedText: cached,
                    boundingBox: entry.item.boundingBox
                )
            } else {
                let terms = await cache.terms(in: entry.text)
                let protected = TermProtector.protect(entry.text, using: terms)
                pending.append((item: entry.item, text: entry.text, protected: protected))
            }
        }

        // FR11: send the new lines to the translation service.
        if !pending.isEmpty {
            let translatedHTML = try await service.translateHTML(
                pending.map { $0.protected.html },
                to: request.targetLanguage
            )
            guard translatedHTML.count == pending.count else {
                throw TranslationError.invalidResponse
            }
            for (entry, html) in zip(pending, translatedHTML) {
                let translated = TermProtector.restore(html, terms: entry.protected.terms)
                resultsByID[entry.item.id] = TranslatedItem(
                    id: entry.item.id,
                    originalText: entry.text,
                    translatedText: translated,
                    boundingBox: entry.item.boundingBox
                )
                await cache.record(source: entry.text, translation: translated)
            }
        }

        // FR13: same order, same id, same position and size as the originals.
        let results = valid.compactMap { resultsByID[$0.item.id] }
        return TranslationOutcome(results: results, rejected: rejected)
    }

    /// FR15: the Clear Context button.
    public func clearContext() async {
        await cache.clear()
    }

    /// FR15: call this when the user picks a different source.
    public func sourceChanged() async {
        await cache.clear()
    }
}

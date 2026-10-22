import XCTest
import CoreGraphics
@testable import GlossaTranslation

/// A fake service so the tests do not need internet or a key.
/// It puts "[language] " in front of every snippet.
final class MockService: TranslationService, @unchecked Sendable {
    var calls: [[String]] = []
    var errorToThrow: TranslationError?

    func translateHTML(_ snippets: [String], to targetLanguage: String) async throws -> [String] {
        calls.append(snippets)
        if let error = errorToThrow { throw error }
        return snippets.map { "[\(targetLanguage)] " + $0 }
    }
}

final class TranslatorTests: XCTestCase {
    let box = CGRect(x: 10, y: 20, width: 100, height: 30)

    func makeTranslator(_ service: MockService, capacity: Int = 50) -> Translator {
        Translator(service: service, cache: ContextCache(capacity: capacity))
    }

    // FR11 and FR13: translated text comes back with the same id and position.
    func testResultKeepsIdAndPosition() async throws {
        let service = MockService()
        let translator = makeTranslator(service)
        let item = RecognizedItem(text: "konnichiwa", boundingBox: box)

        let outcome = try await translator.translate(TranslationRequest(items: [item], targetLanguage: "en"))

        XCTAssertEqual(outcome.results.count, 1)
        XCTAssertEqual(outcome.results[0].id, item.id)
        XCTAssertEqual(outcome.results[0].boundingBox, box)
        XCTAssertEqual(outcome.results[0].translatedText, "[en] konnichiwa")
    }

    // FR13: results stay in the same order as the lines that came in.
    func testResultsKeepOrder() async throws {
        let translator = makeTranslator(MockService())
        let items = ["one", "two", "three"].map { RecognizedItem(text: $0, boundingBox: box) }

        let outcome = try await translator.translate(TranslationRequest(items: items, targetLanguage: "en"))

        XCTAssertEqual(outcome.results.map { $0.id }, items.map { $0.id })
    }

    // FR10: lines with no text are rejected and reported.
    func testEmptyTextIsRejected() async throws {
        let service = MockService()
        let translator = makeTranslator(service)
        let empty = RecognizedItem(text: "", boundingBox: box)
        let spaces = RecognizedItem(text: "   ", boundingBox: box)
        let good = RecognizedItem(text: "hello", boundingBox: box)

        let outcome = try await translator.translate(
            TranslationRequest(items: [empty, spaces, good], targetLanguage: "en")
        )

        XCTAssertEqual(outcome.rejected, [empty.id, spaces.id])
        XCTAssertEqual(outcome.results.count, 1)
        XCTAssertEqual(service.calls.count, 1)
    }

    // FR12: a line we already translated comes from the cache, with no new service call.
    func testRepeatedLineUsesCache() async throws {
        let service = MockService()
        let translator = makeTranslator(service)
        let item = RecognizedItem(text: "same line", boundingBox: box)
        let request = TranslationRequest(items: [item], targetLanguage: "en")

        let first = try await translator.translate(request)
        let second = try await translator.translate(request)

        XCTAssertEqual(service.calls.count, 1)
        XCTAssertEqual(first.results[0].translatedText, second.results[0].translatedText)
    }

    // FR12: a name we translated before keeps its earlier translation inside a new line.
    func testKnownNameKeepsEarlierTranslation() async throws {
        let service = MockService()
        let translator = makeTranslator(service)
        await translator.cache.record(source: "Tanaka", translation: "Mr. Tanaka")
        let item = RecognizedItem(text: "Tanaka is here", boundingBox: box)

        let outcome = try await translator.translate(TranslationRequest(items: [item], targetLanguage: "en"))

        XCTAssertTrue(service.calls[0][0].contains("notranslate"))
        XCTAssertEqual(outcome.results[0].translatedText, "[en] Mr. Tanaka is here")
    }

    // FR12: with an empty cache, the line is translated normally.
    func testEmptyCacheTranslatesWithoutContext() async throws {
        let service = MockService()
        let translator = makeTranslator(service)
        let item = RecognizedItem(text: "plain line", boundingBox: box)

        _ = try await translator.translate(TranslationRequest(items: [item], targetLanguage: "en"))

        XCTAssertFalse(service.calls[0][0].contains("notranslate"))
    }

    // FR15: new translations go into the cache.
    func testTranslationsAreRecorded() async throws {
        let translator = makeTranslator(MockService())
        let item = RecognizedItem(text: "remember me", boundingBox: box)

        _ = try await translator.translate(TranslationRequest(items: [item], targetLanguage: "en"))

        let cached = await translator.cache.lookup("remember me")
        XCTAssertEqual(cached, "[en] remember me")
    }

    // FR15: changing the target language clears the cache.
    func testLanguageChangeClearsCache() async throws {
        let translator = makeTranslator(MockService())
        let first = RecognizedItem(text: "first", boundingBox: box)
        let second = RecognizedItem(text: "second", boundingBox: box)

        _ = try await translator.translate(TranslationRequest(items: [first], targetLanguage: "en"))
        _ = try await translator.translate(TranslationRequest(items: [second], targetLanguage: "fr"))

        let oldEntry = await translator.cache.lookup("first")
        let count = await translator.cache.count
        XCTAssertNil(oldEntry)
        XCTAssertEqual(count, 1)
    }

    // FR15: the Clear Context button and a source change both empty the cache.
    func testClearContextAndSourceChange() async throws {
        let translator = makeTranslator(MockService())
        let item = RecognizedItem(text: "something", boundingBox: box)
        _ = try await translator.translate(TranslationRequest(items: [item], targetLanguage: "en"))

        await translator.clearContext()
        var count = await translator.cache.count
        XCTAssertEqual(count, 0)

        _ = try await translator.translate(TranslationRequest(items: [item], targetLanguage: "en"))
        await translator.sourceChanged()
        count = await translator.cache.count
        XCTAssertEqual(count, 0)
    }

    // FR11 and FR14: a service error is passed up so the app can show the message.
    func testServiceErrorIsThrown() async {
        let service = MockService()
        service.errorToThrow = .timeout
        let translator = makeTranslator(service)
        let item = RecognizedItem(text: "hello", boundingBox: box)

        do {
            _ = try await translator.translate(TranslationRequest(items: [item], targetLanguage: "en"))
            XCTFail("Expected a timeout error")
        } catch {
            XCTAssertEqual(error as? TranslationError, .timeout)
        }
    }

    func testUserMessages() {
        XCTAssertEqual(TranslationError.timeout.userMessage, "Translation unavailable")
        XCTAssertEqual(TranslationError.invalidAPIKey.userMessage, "Translation service key is missing or invalid")
    }
}

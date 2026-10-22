import XCTest
@testable import GlossaTranslation

final class TermProtectorTests: XCTestCase {
    func testEscapeAndUnescapeRoundTrip() {
        let text = "A & B < C > D"
        XCTAssertEqual(TermProtector.unescape(TermProtector.escape(text)), text)
    }

    func testProtectWrapsKnownTerm() {
        let entry = CacheEntry(source: "Tanaka", translation: "Mr. Tanaka")
        let result = TermProtector.protect("Tanaka is here", using: [entry])
        XCTAssertEqual(result.html, "<span class=\"notranslate\">Tanaka</span> is here")
        XCTAssertEqual(result.terms, [entry])
    }

    func testProtectWithNoTermsOnlyEscapes() {
        let result = TermProtector.protect("a < b", using: [])
        XCTAssertEqual(result.html, "a &lt; b")
        XCTAssertTrue(result.terms.isEmpty)
    }

    // The longer name wins over the shorter name inside it.
    func testLongestTermWins() {
        let short = CacheEntry(source: "Tanaka", translation: "T")
        let long = CacheEntry(source: "Tanaka Taro", translation: "TT")
        let result = TermProtector.protect("Tanaka Taro arrived", using: [short, long])
        XCTAssertEqual(result.terms, [long])
    }

    func testRestoreSwapsInEarlierTranslation() {
        let entry = CacheEntry(source: "Tanaka", translation: "Mr. Tanaka")
        let html = "Hello <span class=\"notranslate\">Tanaka</span>, welcome &amp; hi"
        XCTAssertEqual(TermProtector.restore(html, terms: [entry]), "Hello Mr. Tanaka, welcome & hi")
    }

    // If the service damages the tags, we fall back to its plain text.
    func testRestoreFallsBackWhenTagsAreMissing() {
        let entry = CacheEntry(source: "Tanaka", translation: "Mr. Tanaka")
        XCTAssertEqual(TermProtector.restore("Hello Tanaka", terms: [entry]), "Hello Tanaka")
    }
}

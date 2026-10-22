import XCTest
@testable import GlossaTranslation

final class ContextCacheTests: XCTestCase {
    // FR15: the oldest entry is removed when the cache is over capacity.
    func testOldestEntryIsRemoved() async {
        let cache = ContextCache(capacity: 3)
        await cache.record(source: "a", translation: "A")
        await cache.record(source: "b", translation: "B")
        await cache.record(source: "c", translation: "C")
        await cache.record(source: "d", translation: "D")

        let count = await cache.count
        let oldest = await cache.lookup("a")
        let newest = await cache.lookup("d")
        XCTAssertEqual(count, 3)
        XCTAssertNil(oldest)
        XCTAssertEqual(newest, "D")
    }

    // The default size is the 50 entries that FR12 and FR15 ask for.
    func testDefaultCapacityIs50() async {
        let cache = ContextCache()
        for number in 1...60 {
            await cache.record(source: "line \(number)", translation: "T\(number)")
        }
        let count = await cache.count
        let capacity = await cache.capacity
        XCTAssertEqual(capacity, 50)
        XCTAssertEqual(count, 50)
    }

    // Saving the same text again moves it to the newest spot.
    func testRecordingAgainRefreshesEntry() async {
        let cache = ContextCache(capacity: 2)
        await cache.record(source: "a", translation: "A")
        await cache.record(source: "b", translation: "B")
        await cache.record(source: "a", translation: "A2")
        await cache.record(source: "c", translation: "C")

        let a = await cache.lookup("a")
        let b = await cache.lookup("b")
        XCTAssertEqual(a, "A2")
        XCTAssertNil(b)
    }

    func testClear() async {
        let cache = ContextCache()
        await cache.record(source: "a", translation: "A")
        await cache.clear()
        let count = await cache.count
        XCTAssertEqual(count, 0)
    }

    func testTermsOnlyIncludesShortEntriesInsideTheText() async {
        let cache = ContextCache()
        await cache.record(source: "Tanaka", translation: "Mr. Tanaka")
        await cache.record(source: "Sato", translation: "Mr. Sato")
        await cache.record(source: String(repeating: "x", count: 40), translation: "long")

        let found = await cache.terms(in: "Tanaka is here")
        XCTAssertEqual(found.map { $0.source }, ["Tanaka"])
    }
}

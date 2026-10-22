import Foundation
import CoreGraphics
import GlossaTranslation

// Usage:
//   GLOSSA_API_KEY=your_key swift run TranslationDemo en "こんにちは" "ありがとう"
// The first argument is the target language. The rest are lines to translate.

let args = Array(CommandLine.arguments.dropFirst())
guard args.count >= 2 else {
    print("Usage: GLOSSA_API_KEY=your_key swift run TranslationDemo <language> \"text\" [\"text\" ...]")
    exit(1)
}

let key = ProcessInfo.processInfo.environment["GLOSSA_API_KEY"] ?? APIKeyStore.load() ?? ""
let translator = Translator(service: GoogleTranslationService(apiKey: key))

let items = args.dropFirst().enumerated().map { pair in
    RecognizedItem(
        text: pair.element,
        boundingBox: CGRect(x: 0, y: CGFloat(pair.offset) * 30, width: 300, height: 30)
    )
}

do {
    // Two rounds on purpose. In round 2 the lines come from the context cache.
    for round in 1...2 {
        let outcome = try await translator.translate(
            TranslationRequest(items: items, targetLanguage: args[0])
        )
        print("Round \(round)")
        for result in outcome.results {
            print("  \(result.originalText)  ->  \(result.translatedText)   at \(result.boundingBox)")
        }
        let cached = await translator.cache.count
        print("  context cache entries: \(cached)")
    }
} catch let error as TranslationError {
    print(error.userMessage)
} catch {
    print(error)
}

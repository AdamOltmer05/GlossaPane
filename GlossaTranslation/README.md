# GlossaTranslation

The translation step for GlossaPane (CSCI 4830). It takes text from the capture and OCR step,
translates it, and returns the result with its original position for the overlay.

## Which requirements it covers

| Requirement | Where |
|---|---|
| FR10 Receive text in a fixed format, reject empty lines | `RecognizedItem`, `Translator.translate` |
| FR11 Translate with the cloud service, detect language, 5 second timeout | `GoogleTranslationService` |
| FR12 Reuse earlier translations for repeated lines and names | `ContextCache`, `TermProtector`, `Translator` |
| FR13 Return the translation with the same id and position | `TranslatedItem` |
| FR14 Error messages the app can show (not retry logic) | `TranslationError.userMessage` |
| FR15 Cache of 50 entries, cleared on language or source change | `ContextCache`, `Translator.clearContext`, `sourceChanged` |
| NFR3 HTTPS, key in the Keychain and not in logs | `GoogleTranslationService`, `APIKeyStore` |

FR14 retry behavior (try again on the next cycle, message after 3 failures) belongs to the
integration step. This package only throws the error.

## Run the tests (no internet or key needed)

    swift test

## Run the demo (needs a Google Cloud Translation API key)

1. In Google Cloud Console, create a project, enable the Cloud Translation API, and create an API key.
2. Run:

       GLOSSA_API_KEY=your_key swift run TranslationDemo en "こんにちは" "ありがとう"

Round 2 of the demo shows lines coming from the context cache.

Never commit the key. The repo is public. To save the key in the Keychain instead of an
environment variable, call `APIKeyStore.save("your_key")` once.

## How the other steps use it

    let key = APIKeyStore.load() ?? ""
    let translator = Translator(service: GoogleTranslationService(apiKey: key))

    // Bryan's step sends lines (text and position).
    let request = TranslationRequest(items: recognizedItems, targetLanguage: "en")
    let outcome = try await translator.translate(request)

    // AJ's step draws outcome.results. Each has translatedText and boundingBox.

## Known limits in this version

- Name reuse (FR12) only covers short cached lines (2 to 30 characters), like character names.
- The cache lives in memory only, so it resets when the app closes.
- The service is Google Cloud Translation (Basic, v2). The `TranslationService` protocol makes
  it easy to swap later.

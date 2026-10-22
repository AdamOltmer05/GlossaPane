// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GlossaTranslation",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "GlossaTranslation", targets: ["GlossaTranslation"]),
        .executable(name: "TranslationDemo", targets: ["TranslationDemo"]),
    ],
    targets: [
        .target(name: "GlossaTranslation"),
        .executableTarget(name: "TranslationDemo", dependencies: ["GlossaTranslation"]),
        .testTarget(name: "GlossaTranslationTests", dependencies: ["GlossaTranslation"]),
    ]
)

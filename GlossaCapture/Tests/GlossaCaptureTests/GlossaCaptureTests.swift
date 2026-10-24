
import Testing
@testable import GlossaCapture

@Test func displaySourceStoresID() {
    let source = CaptureSource.display(id: "monitor-1")

    #expect(source == .display(id: "monitor-1"))
}

@Test func windowSourceStoresID() {
    let source = CaptureSource.window(id: "window-1")

    #expect(source == .window(id: "window-1"))
}

@Test func regionSourceStoresCoordinates() {
    let source = CaptureSource.region(
        x: 100,
        y: 200,
        width: 500,
        height: 300
    )

    #expect(source == .region(
        x: 100,
        y: 200,
        width: 500,
        height: 300
    ))
}

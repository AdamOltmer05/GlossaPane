
import Foundation

/// Represents the screen source selected by the user.
public enum CaptureSource: Equatable, Sendable {

    // FR2: Select an entire display.
    case display(id: String)

    // FR3: Select an application window.
    case window(id: String)

    // FR4: Select a rectangular screen region.
    case region(
        x: Int,
        y: Int,
        width: Int,
        height: Int
    )

    /// Checks whether the selected source has valid values
    public var isValid: Bool {
        switch self {

        case .display(let id):
            return !id.isEmpty

        case .window(let id):
            return !id.isEmpty

        case .region(_, _, let width, let height):
            return width > 0 && height > 0
        }
    }
}

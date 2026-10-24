# GlossaCapture

The screen capture and OCR step for GlossaPane (CSCI 4830). It handles the selection of displays, application windows, and screen regions, with plans to capture images and recognize text for the translation step.

This first version establishes the source selection data model and basic validation.

## Which requirements it covers

| Requirement | Where |
|---|---|
| FR2 Select an entire display as the source | `CaptureSource.display` |
| FR3 Select an application window as the source | `CaptureSource.window` |
| FR4 Select a rectangular screen region | `CaptureSource.region` |

These requirements are partially implemented. The current package represents and validates source selections but does not yet perform actual screen selection or capture.

## Run the tests

From the `GlossaCapture` directory, run:

```powershell
swift test
```

The package currently has 7 tests covering source types, equality, and validation.

All 7 tests pass on Windows.

## How the other steps use it

```swift
import GlossaCapture

// Select an entire display.
let display = CaptureSource.display(id: "monitor-1")

// Select an application window.
let window = CaptureSource.window(id: "window-1")

// Select a rectangular screen region.
let region = CaptureSource.region(
    x: 100,
    y: 200,
    width: 500,
    height: 300
)

// Check whether the selected source is valid.
if region.isValid {
    print("Valid capture source")
}
```

Future versions will use the selected source to capture screen images and recognize text. The recognized text and its position will then be passed to the translation step.

## Known limits in this version

- Display and window selection currently use identifiers only. Actual source discovery is not implemented.
- Region selection stores coordinates and dimensions but does not provide an interactive selection tool.
- Validation checks for empty identifiers and nonpositive region dimensions. It does not verify whether the selected source exists.
- Screen image capture and OCR are not yet implemented.
- Integration with the translation module will be completed in a later sprint.

## Next steps

- Implement a screen capture service.
- Add Windows-compatible display and window capture.
- Support capturing a selected screen region.
- Add OCR to recognize text and return its position.
- Connect recognized text to the translation module.
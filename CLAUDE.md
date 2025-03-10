# RoomPlan Project Guide

## Build Commands
- Open in Xcode: `open RoomPlanExampleApp.xcodeproj`
- Build: ⌘B (Command+B)
- Run on simulator: ⌘R (Command+R)
- Run on device: Select device and use ⌘R
- Clean: ⇧⌘K (Shift+Command+K)

## Code Style & Guidelines
- Swift standard naming: camelCase for variables/functions, PascalCase for types
- Use descriptive variable names (e.g., `roomCaptureView`, not `rcView`)
- Group related properties and methods together with MARK comments
- Use IBOutlet for storyboard connections with descriptive names
- Make private helpers explicitly `private func`
- Document complex logic with inline comments

## Project Patterns & Conventions
- UIKit with Storyboard-based navigation
- MVC architecture pattern
- Delegate pattern for view controller communication
- Uses RoomPlan Apple framework for AR scanning
- SCNView/SceneKit for 3D visualization
- Uses UIActivityViewController for sharing exports
- JSON encoding for data export
- Exports room data in USDZ format
- Handles both metric and imperial measurements

## Improvement Checklist

### Critical Fixes
- [x] **Fix Quick Look Preview Crash**: Replace `fatalError()` with proper alert
- [x] **Add Error Handling for 3D Model Generation**: Provide user feedback and UI recovery
- [x] **Improve Export Error Handling**: Add specific handlers for JSON encoding/export

### High Priority
- [x] **Fix Memory Management**: Add cleanup for temporary export files
- [x] **Ensure Thread Safety**: Move UI updates to main thread
- [x] **Handle Null Room Data**: Add guards and error states for missing data

### Medium Priority
- [x] **Replace Fixed Layout with Auto Layout**: Fix scrollView content sizing to be dynamic
- [x] **Refactor Duplicate SceneKit Code**: Consolidate setup code into reusable methods
- [x] **Improve Navigation Flow**: Create clearer patterns between scan and results screens

### Low Priority
- [x] **Add Accessibility Support**: Implement VoiceOver compatibility
- [x] **Persist User Preferences**: Save unit preference (metric/imperial)
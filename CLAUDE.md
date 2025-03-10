# ArchiNet RoomPlan Guide

## Project Purpose & Vision
ArchiNet RoomPlan is a professional-grade iOS application designed specifically for architects, interior designers, and space planning professionals. The app streamlines the traditionally time-consuming process of measuring, documenting, and planning interior spaces.

By leveraging Apple's RoomPlan API and advanced AR capabilities, ArchiNet RoomPlan allows users to:
- Rapidly capture precise spatial measurements of rooms, floors, or entire buildings
- Generate professional-quality documentation required for architectural space planning
- Export to industry-standard formats compatible with CAD systems and BIM software
- Create detailed planning documents with material specifications and dimensions
- Streamline the transition from initial site survey to detailed design planning

The application aims to significantly reduce the time and labor involved in the initial phases of architectural projects, enhance measurement accuracy, and provide a seamless workflow from physical space to digital planning environment.

## Current Application State (Updated March 10, 2025)

### Core Functionality
The application currently provides:
- Room scanning using Apple's RoomPlan API (iOS 18 compatible)
- 3D visualization of scanned rooms using SceneKit
- Basic export capabilities (USDZ and JSON formats)
- Measurement unit switching (metric/imperial) with UserDefaults persistence
- VoiceOver accessibility support
- Error recovery and graceful degradation
- Memory management with proper resource cleanup

### Architecture & Implementation Details
- **Controller Structure**: Two primary view controllers:
  - `RoomCaptureViewController`: Manages the scanning process using RoomPlan API
  - `ResultsViewController`: Displays and exports captured room data
  
- **Data Flow**:
  1. User initiates scan in RoomCaptureViewController
  2. RoomPlan API captures room data through AR
  3. On completion, data is passed to ResultsViewController
  4. ResultsViewController processes data into visualizations and exportable formats
  
- **Key Technical Solutions**:
  - Using string comparison for room object categorization (improves API version compatibility)
  - SIMD3<Float> (vector) handling for dimension data in iOS 18
  - Proper memory management with cleanup in deinit methods
  - Thread safety with main thread UI updates
  - Auto Layout for responsive UI across devices
  - Refactored SceneKit methods to reduce code duplication
  - Improved navigation with explicit user choice between results and continued scanning

### Known Limitations
- Currently limited to single-room scanning
- Basic export formats only (USDZ/JSON), no CAD formats
- No annotation or markup capabilities
- Limited handling of complex architectural elements
- Simple measurement display without professional notations
- No project organization or multi-room relationships
- Limited visualization options (no lighting simulation, material visualization)

### Recent Improvements
All critical, high, medium, and low priority items from our initial improvement checklist have been implemented, including iOS 18 compatibility fixes.

## Build Commands
- Open in Xcode: `open RoomPlanExampleApp.xcodeproj`
- Build: ⌘B (Command+B)
- Run on simulator: ⌘R (Command+R)
- Run on device: Select device and use ⌘R
- Clean: ⇧⌘K (Shift+Command+K)

## Technical Details & Conventions

### Code Style Guidelines
- **Swift Naming Conventions**:
  - camelCase for variables, functions, and method names (`setupRoomView`)
  - PascalCase for type names (classes, structs, enums, protocols)
  - Use descriptive names that explain purpose (`roomCaptureView` not `rcView`)
  - Include parameter descriptors in function names (`setupView(with dimensions:)`)

- **Code Organization**:
  - Group related properties/methods with MARK comments
  - Properties first, then lifecycle methods, then action methods
  - Keep files under 1000 lines when possible
  - Make helper methods private with explicit `private func` declaration
  - Use extensions to separate protocol implementations

- **UI Layout**:
  - Use Auto Layout exclusively (avoid frame-based layout)
  - Set `translatesAutoresizingMaskIntoConstraints = false`
  - Use visual hierarchy with consistent spacing
  - Make UI elements accessible with proper labels
  - Support Dark Mode with system colors

- **Documentation**:
  - Document all public methods and properties
  - Add inline comments for complex logic
  - Use /// format for documentation comments
  - Explain "why" not just "what" the code does
  - Document workarounds and edge cases

### Architecture & Design Patterns
- **Application Structure**:
  - UIKit framework with Storyboard-based navigation
  - MVC architecture pattern
  - Single storyboard with segue-based navigation
  - Uses standard UIKit components with minor customization
  - Auto Layout for responsive UI across devices
 
- **Primary Design Patterns**:
  - **Delegation**: For view controller communication
  - **Model-View-Controller**: Clear separation of concerns
  - **Observer Pattern**: For UI updates and state changes
  - **Coordinator Pattern**: For navigation in future implementation
  - **Repository Pattern**: For data persistence in future implementation

- **Key Technology Integrations**:
  - **RoomPlan**: Core API for room scanning (iOS 16+)
  - **SceneKit**: For 3D visualization of room data
  - **QuickLook**: For 3D model preview
  - **UserDefaults**: For simple preferences persistence
  - **UIActivityViewController**: For sharing export files

- **Data Formats & Handling**:
  - USDZ for 3D model export
  - JSON for structured data export
  - In-memory model using CapturedRoom from RoomPlan
  - Unit conversion between metric/imperial measurement systems
  - Temporart file management with proper cleanup

## Completed Implementation Work

### Recently Implemented Improvements
Below is a detailed record of all improvements implemented in the current version, including specific technical approaches for each item:

#### Critical Fixes
- [x] **QuickLook Preview Crash Fix**
  - **Issue**: App crashed with `fatalError("Model URL not available")` when model URL was nil
  - **Solution**: Replaced fatal error with graceful error handling
  - **Implementation**: Added QLPreviewControllerDelegate, implemented dismissal with alert message, and supplied fallback URL
  - **Files Modified**: ResultsViewController.swift (previewController method)

- [x] **3D Model Generation Error Handling**
  - **Issue**: Failed model generation provided no user feedback and left UI in broken state
  - **Solution**: Added comprehensive error handling with UI state recovery
  - **Implementation**: Wrapped model generation in proper try/catch, added error alerts, re-enabled buttons on failure
  - **Files Modified**: ResultsViewController.swift (generateModel method)

- [x] **Export Error Handling Enhancement**
  - **Issue**: Generic error handling for export operations
  - **Solution**: Added specific error handling for each export stage
  - **Implementation**: Separated error contexts (directory creation, JSON encoding, model export), added specific error messages
  - **Files Modified**: ResultsViewController.swift, RoomCaptureViewController.swift (export methods)

#### Architecture & Performance Improvements
- [x] **Memory Management**
  - **Issue**: Temporary files accumulated without cleanup
  - **Solution**: Implemented proper file lifecycle management
  - **Implementation**: Added deinit cleanup methods, explicit cleanup triggers for abandoned files
  - **Technical Approach**: Using FileManager for directory cleanup, nil-ing references after cleanup

- [x] **Thread Safety Improvements**
  - **Issue**: UI updates happening on background threads
  - **Solution**: Ensured all UI updates happen on main thread
  - **Implementation**: Added DispatchQueue.main.async wrappers, weak self references in closure captures
  - **Files Modified**: Both view controllers, focusing on async completion handlers

- [x] **Null Data Handling**
  - **Issue**: App failed ungracefully with missing room data
  - **Solution**: Added empty state handling and user feedback
  - **Implementation**: Created updateEmptyState method with placeholder UI, visual indicators for missing data
  - **Technical Detail**: Added accessibility announcements for state changes

#### User Interface & Experience
- [x] **Auto Layout Implementation**
  - **Issue**: Fixed layout using frames with hardcoded dimensions (height: 1000)
  - **Solution**: Converted to dynamic Auto Layout system
  - **Implementation**: Removed all frame-based sizing, added NSLayoutConstraint activation, set translatesAutoresizingMaskIntoConstraints = false
  - **Key Benefit**: UI now adapts to all screen sizes and orientations

- [x] **SceneKit Code Refactoring**
  - **Issue**: Duplicate code for SceneKit setup and configuration
  - **Solution**: Consolidated into reusable helper methods
  - **Implementation**: Created methods like setupSceneCamera, createFloorNode, etc.
  - **Technical Approach**: Used function composition with clear parameter naming

- [x] **Navigation Flow Improvement**
  - **Issue**: Forced navigation to results screen after scan
  - **Solution**: Added user choice for next steps
  - **Implementation**: Added alert with "View Results" and "Continue Scanning" options
  - **UX Improvement**: Added "Continue Scanning" button in results view for circular flow

#### Quality of Life Features
- [x] **Accessibility Support**
  - **Issue**: Limited accessibility for VoiceOver users
  - **Solution**: Comprehensive accessibility implementation
  - **Implementation**: Added accessibility labels, hints, traits for all UI elements
  - **Advanced Features**: Dynamic accessibility updates, announcement of state changes

- [x] **User Preferences Persistence**
  - **Issue**: Unit choice (metric/imperial) reset on app restart
  - **Solution**: Added preference persistence using UserDefaults
  - **Implementation**: Store/retrieve preference with "RoomPlanUseMetricUnits" key
  - **UX Improvement**: Maintains consistent experience across app sessions

#### iOS 18 Compatibility
- [x] **API Updates**
  - **Issue**: Breaking changes in RoomPlan API for iOS 18
  - **Solution**: Updated code to support both old and new API patterns
  - **Implementation**: Using string-based category identification instead of direct enum cases
  - **Technical Detail**: Added robust string comparison fallbacks

- [x] **Dimension Handling**
  - **Issue**: Dimension type changed from struct to simd_float3 vector
  - **Solution**: Updated code to work with vector components
  - **Implementation**: Mapped x/y/z vector components to width/height/length
  - **Technical Note**: Maintained backward compatibility where possible

- [x] **Enum Compatibility**
  - **Issue**: Category enum cases changed in iOS 18
  - **Solution**: String-based comparison instead of direct case matching
  - **Implementation**: Used getCategoryName method with flexible string matching
  - **Technical Approach**: Pattern matching with contains() for resilience

- [x] **Initialization Parameter Updates**
  - **Issue**: Required parameters added to UIKit class initializers
  - **Solution**: Updated all initializer calls to include required parameters
  - **Implementation**: Added frame parameters to UITableView, QLPreviewController
  - **Affected Classes**: Multiple UIKit components throughout the app

## Implementation Decisions & Rationale

### Key Design Decisions
This section explains the reasoning behind our major implementation choices:

1. **String-based Category Matching**
   - **Decision**: Use string comparison for object categories instead of direct enum case matching
   - **Rationale**: Provides resilience against API changes between iOS versions
   - **Trade-offs**: Slightly less performant but significantly more stable across API versions
   - **Alternative Considered**: Version-specific code paths, rejected due to maintenance complexity

2. **SceneKit for 3D Visualization**
   - **Decision**: Use SceneKit rather than Metal or RealityKit
   - **Rationale**: Better balance of performance and development complexity for our current needs
   - **Trade-offs**: Less graphical power than Metal but simpler to implement
   - **Future Consideration**: May migrate to RealityKit for more advanced visualization needs

3. **MVC Architecture**
   - **Decision**: Use Model-View-Controller architecture
   - **Rationale**: Familiar pattern that aligns well with UIKit design
   - **Trade-offs**: Less separation than MVVM but simpler to implement and maintain
   - **Future Consideration**: Possible migration to MVVM for better testability

4. **UserDefaults for Preferences**
   - **Decision**: Store user preferences in UserDefaults
   - **Rationale**: Simple, built-in solution adequate for current limited preference needs
   - **Trade-offs**: Less structured than Core Data but sufficient for simple key-value storage
   - **Future Consideration**: Custom preference manager as app complexity grows

5. **Auto Layout**
   - **Decision**: Exclusive use of Auto Layout constraint system
   - **Rationale**: Ensures responsive UI across all device sizes
   - **Trade-offs**: More verbose setup code but much better adaptability
   - **Implementation Note**: Completely replaced frame-based layout

6. **Error Handling Approach**
   - **Decision**: Context-specific error handling with user feedback
   - **Rationale**: Provides meaningful recovery paths for different error scenarios
   - **Implementation**: Custom error types with specific messages tailored to architectural context
   - **UX Consideration**: Non-technical error messages focused on user action

## Architectural Space Planning Roadmap

Our development roadmap is designed to transform ArchiNet RoomPlan into a comprehensive architectural space planning solution. The roadmap progresses from establishing solid foundations to implementing professional-grade features specifically needed by architects and designers:

### Phase 1: Foundation Strengthening (1-2 weeks)
- [ ] **Precision Measurement Reliability**
  - Implement structured logging for measurement processes
  - Add dimensional accuracy verification systems
  - Create calibration tools for precise architectural measurements
  - Develop error handling for measurement edge cases

- [ ] **Architectural Data Integrity**
  - Create specialized error handling for architectural data
  - Add validation for architectural proportions and relationships
  - Implement recovery strategies for incomplete scans
  - Add professional terminology in user-facing messages

- [ ] **Professional Reliability Testing**
  - Setup unit tests for dimensional accuracy
  - Add verification tests for architectural elements (walls, doors, windows)
  - Implement comparison tests against known measurements
  - Create performance tests for larger spaces and complex geometry

- [ ] **Professional-grade Debugging**
  - Add measurement precision analysis tools
  - Implement spatial relationship validation
  - Add dimensional consistency checking
  - Create architectural element identification verification

### Phase 2: Professional User Experience (2-3 weeks)
- [ ] **Architectural UI/Visual Design**
  - Implement professional architectural UI conventions
  - Create industry-standard notation and symbols
  - Add architectural scale indicators and grid systems
  - Develop drafting-quality visual presentation

- [ ] **Professional Workflow Navigation**
  - Implement architecture-specific process flows
  - Add specialized space planning navigation tools
  - Create project management hierarchy
  - Develop multi-space relationship navigation

- [ ] **Large-Scale Performance Optimization**
  - Optimize for whole-building scanning
  - Implement efficient handling of complex architectural elements
  - Add level-of-detail management for architectural visualization
  - Create specialized architectural data structures

- [ ] **Professional Accessibility**
  - Implement accessibility standards for architectural visualization
  - Add audio descriptions using architectural terminology
  - Create tactile feedback for measurement precision
  - Ensure readability of architectural notations and dimensions

### Phase 3: Architecture Integration & Formats (2-3 weeks)
- [ ] **CAD Integration**
  - Add DXF/DWG export functionality
  - Implement IFC format support for BIM systems
  - Create dimension annotation capabilities
  - Add material property tagging

- [ ] **Professional Documentation Generation**
  - Implement architectural template system
  - Add standard drawing sheet formats (A0-A4)
  - Create specification document generation
  - Implement scale management system

- [ ] **Multi-space Management**
  - Enable project-based organization
  - Add features to connect multiple rooms
  - Implement elevation references
  - Create building level management

- [ ] **iOS Ecosystem Integration**
  - Add widget support for recent projects
  - Implement Siri shortcuts for professional workflows
  - Add iCloud sync for project data
  - Create integrated backup system

### Phase 4: Professional Features (2-3 weeks)
- [ ] **Advanced Measurement Tools**
  - Add specialized architectural measurement capabilities
  - Implement material surface area calculations
  - Create precise corner and angle measurements
  - Add structural element identification

- [ ] **Collaboration Tools**
  - Implement project sharing capabilities
  - Add commenting and markup features
  - Create revision tracking system
  - Add cloud-based team collaboration

- [ ] **Architecture-specific Visualization**
  - Add lighting simulation capabilities
  - Implement interior rendering features
  - Create material visualization options
  - Add furniture and fixture library

- [ ] **Documentation & Code Quality**
  - Create comprehensive code documentation
  - Add architecture-focused API documentation
  - Implement professional user guides
  - Create integration documentation for CAD systems

### Phase 5: Extended Professional Capabilities (Future Roadmap)
- [ ] Integration with popular CAD software (AutoCAD, Revit, ArchiCAD)
- [ ] Advanced material specification and cost estimation
- [ ] Building code compliance checking
- [ ] Environmental analysis and sustainability metrics
- [ ] Virtual reality presentation capabilities
- [ ] Client presentation tools with real-time modification
- [ ] Construction document generation
- [ ] Contractor specification packages
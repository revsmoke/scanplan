import SwiftUI
import Foundation
import CoreGraphics

// MARK: - UI Themes and Modes

/// UI theme for professional interface design
enum UITheme: String, CaseIterable, Codable {
    case professional = "professional"
    case modern = "modern"
    case minimal = "minimal"
    case dark = "dark"
    case light = "light"
    case highContrast = "high_contrast"
    
    var displayName: String {
        switch self {
        case .professional: return "Professional"
        case .modern: return "Modern"
        case .minimal: return "Minimal"
        case .dark: return "Dark"
        case .light: return "Light"
        case .highContrast: return "High Contrast"
        }
    }
    
    var primaryColor: Color {
        switch self {
        case .professional: return Color(red: 0.2, green: 0.4, blue: 0.8)
        case .modern: return Color(red: 0.3, green: 0.6, blue: 0.9)
        case .minimal: return Color(red: 0.5, green: 0.5, blue: 0.5)
        case .dark: return Color(red: 0.1, green: 0.1, blue: 0.1)
        case .light: return Color(red: 0.9, green: 0.9, blue: 0.9)
        case .highContrast: return Color.black
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .professional: return Color(red: 0.95, green: 0.95, blue: 0.97)
        case .modern: return Color(red: 0.98, green: 0.98, blue: 0.99)
        case .minimal: return Color.white
        case .dark: return Color(red: 0.05, green: 0.05, blue: 0.05)
        case .light: return Color.white
        case .highContrast: return Color.white
        }
    }
}

/// Interface mode for different app states
enum InterfaceMode: String, CaseIterable, Codable {
    case scanning = "scanning"
    case analysis = "analysis"
    case review = "review"
    case settings = "settings"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var icon: String {
        switch self {
        case .scanning: return "viewfinder"
        case .analysis: return "chart.bar.xaxis"
        case .review: return "doc.text.magnifyingglass"
        case .settings: return "gear"
        }
    }
}

// MARK: - UI State Management

/// Comprehensive UI state
struct UIState: Codable {
    let theme: UITheme
    let mode: InterfaceMode
    let navigationState: NavigationState
    let interactionState: InteractionState
    let visualizationState: VisualizationState
    let performance: UIPerformance
}

/// Navigation state management
struct NavigationState: Codable {
    var currentMode: InterfaceMode = .scanning
    var availableActions: [UIAction] = []
    var navigationHistory: [NavigationEvent] = []
    var scanningProgress: ScanningProgress?
    
    var canNavigateBack: Bool {
        return navigationHistory.count > 1
    }
    
    var previousMode: InterfaceMode? {
        return navigationHistory.dropLast().last?.mode
    }
}

/// Navigation event tracking
struct NavigationEvent: Codable {
    let mode: InterfaceMode
    let timestamp: Date
}

/// Interaction state management
struct InteractionState: Codable {
    var lastInteraction: UserInteraction?
    var interactionResult: InteractionResult?
    var availableInteractions: [InteractionType] = []
    var interactionContext: InteractionContext?
    var isInteractionEnabled: Bool = true
}

/// Visualization state management
struct VisualizationState: Codable {
    var currentData: VisualizationData?
    var activeVisualizations: [VisualizationType] = []
    var visualizationMode: VisualizationMode = .realTime
    var isVisualizationEnabled: Bool = true
}

// MARK: - User Interactions

/// User interaction definition
struct UserInteraction: Identifiable, Codable {
    let id = UUID()
    let type: InteractionType
    let location: CGPoint
    let timestamp: Date
    let gestureType: GestureType?
    let voiceCommand: String?
    let context: String?
    
    init(type: InteractionType, location: CGPoint = .zero, gestureType: GestureType? = nil, voiceCommand: String? = nil, context: String? = nil) {
        self.type = type
        self.location = location
        self.timestamp = Date()
        self.gestureType = gestureType
        self.voiceCommand = voiceCommand
        self.context = context
    }
}

/// Interaction types
enum InteractionType: String, CaseIterable, Codable {
    case tap = "tap"
    case gesture = "gesture"
    case voice = "voice"
    case keyboard = "keyboard"
    
    var displayName: String {
        return rawValue.capitalized
    }
}

/// Gesture types
enum GestureType: String, CaseIterable, Codable {
    case pinch = "pinch"
    case pan = "pan"
    case rotation = "rotation"
    case longPress = "long_press"
    case swipe = "swipe"
    
    var displayName: String {
        return rawValue.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

/// Interaction result
struct InteractionResult: Codable {
    let isSuccessful: Bool
    let resultType: InteractionResultType
    let message: String?
    let data: InteractionResultData?
    
    static func success(type: InteractionResultType, message: String? = nil, data: InteractionResultData? = nil) -> InteractionResult {
        return InteractionResult(isSuccessful: true, resultType: type, message: message, data: data)
    }
    
    static func failure(message: String) -> InteractionResult {
        return InteractionResult(isSuccessful: false, resultType: .error, message: message, data: nil)
    }
}

enum InteractionResultType: String, CaseIterable, Codable {
    case success = "success"
    case navigation = "navigation"
    case dataUpdate = "data_update"
    case error = "error"
    
    var displayName: String {
        return rawValue.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

/// Interaction result data
struct InteractionResultData: Codable {
    let actionPerformed: String?
    let dataChanged: Bool
    let navigationTarget: InterfaceMode?
    let visualizationUpdate: VisualizationUpdate?
}

/// Interaction context
struct InteractionContext: Codable {
    let data: VisualizationData
    let availableActions: [String] = []
    let constraints: [String] = []
}

// MARK: - UI Actions

/// UI action definitions
enum UIAction: String, CaseIterable, Codable {
    case startScan = "start_scan"
    case pauseScan = "pause_scan"
    case stopScan = "stop_scan"
    case analyzeData = "analyze_data"
    case exportResults = "export_results"
    case shareResults = "share_results"
    case reviewResults = "review_results"
    case editResults = "edit_results"
    case updateSettings = "update_settings"
    case resetSettings = "reset_settings"
    case switchMode = "switch_mode"
    
    var displayName: String {
        return rawValue.replacingOccurrences(of: "_", with: " ").capitalized
    }
    
    var icon: String {
        switch self {
        case .startScan: return "play.fill"
        case .pauseScan: return "pause.fill"
        case .stopScan: return "stop.fill"
        case .analyzeData: return "chart.bar.xaxis"
        case .exportResults: return "square.and.arrow.up"
        case .shareResults: return "square.and.arrow.up"
        case .reviewResults: return "doc.text.magnifyingglass"
        case .editResults: return "pencil"
        case .updateSettings: return "gear"
        case .resetSettings: return "arrow.clockwise"
        case .switchMode: return "arrow.left.arrow.right"
        }
    }
}

// MARK: - View Types

/// View type definitions
enum ViewType: String, CaseIterable, Codable {
    case scanningView = "scanning_view"
    case analysisView = "analysis_view"
    case reviewView = "review_view"
    case settingsView = "settings_view"
    case metricsView = "metrics_view"
    case progressView = "progress_view"
    case dataVisualizationView = "data_visualization_view"
    case summaryView = "summary_view"
    case exportView = "export_view"
    case preferencesView = "preferences_view"
    
    var displayName: String {
        return rawValue.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

// MARK: - Data Visualization

/// Visualization data structure
struct VisualizationData: Identifiable, Codable {
    let id = UUID()
    let type: VisualizationDataType
    let title: String
    let data: [DataPoint]
    let metadata: VisualizationMetadata
    let timestamp: Date
    
    init(from scanningData: ScanningData) {
        self.type = .realTimeMetrics
        self.title = "Real-Time Scanning Metrics"
        self.data = scanningData.toDataPoints()
        self.metadata = VisualizationMetadata(
            chartType: .lineChart,
            colorScheme: .professional,
            animationEnabled: true
        )
        self.timestamp = Date()
    }
    
    static func empty() -> VisualizationData {
        return VisualizationData(
            type: .empty,
            title: "No Data",
            data: [],
            metadata: VisualizationMetadata(),
            timestamp: Date()
        )
    }
}

/// Visualization data types
enum VisualizationDataType: String, CaseIterable, Codable {
    case realTimeMetrics = "real_time_metrics"
    case scanningProgress = "scanning_progress"
    case analysisResults = "analysis_results"
    case performanceMetrics = "performance_metrics"
    case empty = "empty"
    
    var displayName: String {
        return rawValue.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

/// Data point for visualizations
struct DataPoint: Identifiable, Codable {
    let id = UUID()
    let x: Double
    let y: Double
    let label: String?
    let category: String?
    let timestamp: Date
    
    init(x: Double, y: Double, label: String? = nil, category: String? = nil) {
        self.x = x
        self.y = y
        self.label = label
        self.category = category
        self.timestamp = Date()
    }
}

/// Visualization metadata
struct VisualizationMetadata: Codable {
    let chartType: ChartType
    let colorScheme: ColorScheme
    let animationEnabled: Bool
    let interactionEnabled: Bool
    let showLegend: Bool
    let showAxes: Bool
    
    init() {
        self.chartType = .lineChart
        self.colorScheme = .professional
        self.animationEnabled = true
        self.interactionEnabled = true
        self.showLegend = true
        self.showAxes = true
    }
    
    init(chartType: ChartType, colorScheme: ColorScheme, animationEnabled: Bool) {
        self.chartType = chartType
        self.colorScheme = colorScheme
        self.animationEnabled = animationEnabled
        self.interactionEnabled = true
        self.showLegend = true
        self.showAxes = true
    }
}

/// Chart types
enum ChartType: String, CaseIterable, Codable {
    case lineChart = "line_chart"
    case barChart = "bar_chart"
    case pieChart = "pie_chart"
    case scatterPlot = "scatter_plot"
    case areaChart = "area_chart"
    case heatmap = "heatmap"
    
    var displayName: String {
        return rawValue.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

/// Color schemes
enum ColorScheme: String, CaseIterable, Codable {
    case professional = "professional"
    case vibrant = "vibrant"
    case monochrome = "monochrome"
    case pastel = "pastel"
    
    var displayName: String {
        return rawValue.capitalized
    }
}

/// Visualization types
enum VisualizationType: String, CaseIterable, Codable {
    case realTimeMetrics = "real_time_metrics"
    case progressIndicator = "progress_indicator"
    case scanningOverlay = "scanning_overlay"
    case dataCharts = "data_charts"
    case `3dVisualization` = "3d_visualization"
    case statisticsView = "statistics_view"
    case summaryCharts = "summary_charts"
    case comparisonView = "comparison_view"
    case reportView = "report_view"
    case preferencesView = "preferences_view"
    
    var displayName: String {
        return rawValue.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

/// Visualization modes
enum VisualizationMode: String, CaseIterable, Codable {
    case realTime = "real_time"
    case interactive = "interactive"
    case static = "static"
    case configuration = "configuration"
    
    var displayName: String {
        return rawValue.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

/// Visualization update
struct VisualizationUpdate: Codable {
    let type: VisualizationType
    let data: VisualizationData
    let animationDuration: Double
    let updateReason: String
}

// MARK: - Performance Metrics

/// Real-time metrics
struct RealTimeMetrics: Codable {
    var frameRate: Float = 60.0
    var memoryUsage: Float = 0.0
    var processingTime: TimeInterval = 0.0
    var accuracy: Float = 0.0
    var updateTimestamp: Date = Date()
    
    init() {}
    
    init(from metrics: ScanningMetrics) {
        self.frameRate = metrics.frameRate
        self.memoryUsage = metrics.memoryUsage
        self.processingTime = metrics.processingTime
        self.accuracy = metrics.accuracy
        self.updateTimestamp = Date()
    }
}

/// UI performance metrics
struct UIPerformance: Codable {
    let frameRate: Float
    let memoryUsage: Float
    let renderTime: TimeInterval
    let interactionLatency: TimeInterval
    let animationSmoothnessScore: Float
    let lastUpdate: Date
    
    init() {
        self.frameRate = 60.0
        self.memoryUsage = 0.0
        self.renderTime = 0.016
        self.interactionLatency = 0.001
        self.animationSmoothnessScore = 1.0
        self.lastUpdate = Date()
    }
    
    init(frameRate: Float, memoryUsage: Float, renderTime: TimeInterval, interactionLatency: TimeInterval, animationSmoothnessScore: Float) {
        self.frameRate = frameRate
        self.memoryUsage = memoryUsage
        self.renderTime = renderTime
        self.interactionLatency = interactionLatency
        self.animationSmoothnessScore = animationSmoothnessScore
        self.lastUpdate = Date()
    }
    
    var performanceLevel: PerformanceLevel {
        if frameRate > 55 && renderTime < 0.02 && animationSmoothnessScore > 0.9 {
            return .excellent
        } else if frameRate > 45 && renderTime < 0.03 && animationSmoothnessScore > 0.8 {
            return .good
        } else if frameRate > 30 && renderTime < 0.05 && animationSmoothnessScore > 0.7 {
            return .acceptable
        } else {
            return .poor
        }
    }
}

/// UI performance metrics structure
struct UIPerformanceMetrics: Codable {
    let frameRate: Float
    let memoryUsage: Float
    let renderTime: TimeInterval
    let interactionLatency: TimeInterval
    let animationPerformance: AnimationPerformanceMetrics
}

/// Animation performance metrics
struct AnimationPerformanceMetrics: Codable {
    let smoothnessScore: Float
    let droppedFrames: Int
    let averageFrameTime: TimeInterval
    let jankEvents: Int
    
    init() {
        self.smoothnessScore = 1.0
        self.droppedFrames = 0
        self.averageFrameTime = 0.016
        self.jankEvents = 0
    }
}

// MARK: - Haptic Feedback

/// Haptic event types
enum HapticEvent: String, CaseIterable {
    case modeSwitch = "mode_switch"
    case interaction = "interaction"
    case success = "success"
    case error = "error"

    var displayName: String {
        return rawValue.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

// MARK: - Scanning Data Integration

/// Scanning data for UI integration
struct ScanningData: Codable {
    let sessionId: UUID
    let timestamp: Date
    let metrics: ScanningMetrics
    let progress: ScanningProgress
    let roomData: RoomData?

    func toDataPoints() -> [DataPoint] {
        var points: [DataPoint] = []

        // Convert metrics to data points
        points.append(DataPoint(x: 0, y: Double(metrics.frameRate), label: "Frame Rate", category: "Performance"))
        points.append(DataPoint(x: 1, y: Double(metrics.accuracy), label: "Accuracy", category: "Quality"))
        points.append(DataPoint(x: 2, y: Double(metrics.memoryUsage), label: "Memory", category: "Performance"))
        points.append(DataPoint(x: 3, y: metrics.processingTime * 1000, label: "Processing Time", category: "Performance"))

        return points
    }
}

/// Scanning metrics
struct ScanningMetrics: Codable {
    let frameRate: Float
    let accuracy: Float
    let memoryUsage: Float
    let processingTime: TimeInterval
    let pointCloudSize: Int
    let surfaceCount: Int
}

/// Scanning progress
struct ScanningProgress: Codable {
    let percentage: Float // 0.0 - 1.0
    let currentStage: ScanningStage
    let estimatedTimeRemaining: TimeInterval?
    let completedTasks: [String]
    let totalTasks: [String]

    var isComplete: Bool {
        return percentage >= 1.0
    }

    var progressDescription: String {
        return "\(Int(percentage * 100))% - \(currentStage.displayName)"
    }
}

/// Scanning stages
enum ScanningStage: String, CaseIterable, Codable {
    case initializing = "initializing"
    case scanning = "scanning"
    case processing = "processing"
    case analyzing = "analyzing"
    case finalizing = "finalizing"
    case complete = "complete"

    var displayName: String {
        return rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .initializing: return "gear"
        case .scanning: return "viewfinder"
        case .processing: return "cpu"
        case .analyzing: return "chart.bar.xaxis"
        case .finalizing: return "checkmark.circle"
        case .complete: return "checkmark.circle.fill"
        }
    }
}

/// Room data for visualization
struct RoomData: Codable {
    let roomId: UUID
    let roomType: String
    let dimensions: RoomDimensions
    let surfaces: [SurfaceData]
    let objects: [ObjectData]
    let materials: [MaterialData]
}

/// Room dimensions
struct RoomDimensions: Codable {
    let width: Float
    let height: Float
    let depth: Float
    let area: Float
    let volume: Float
}

/// Surface data
struct SurfaceData: Codable {
    let surfaceId: UUID
    let type: String
    let area: Float
    let material: String
    let confidence: Float
}

/// Object data
struct ObjectData: Codable {
    let objectId: UUID
    let type: String
    let position: SIMD3<Float>
    let dimensions: SIMD3<Float>
    let confidence: Float
}

/// Material data
struct MaterialData: Codable {
    let materialId: UUID
    let type: String
    let properties: [String: Float]
    let coverage: Float
    let confidence: Float
}

// MARK: - Data Sources

/// Scanning data source protocol
protocol ScanningDataSourceProtocol {
    var dataPublisher: AnyPublisher<ScanningData, Never> { get }
    func startDataCollection()
    func stopDataCollection()
}

/// Metrics data source protocol
protocol MetricsDataSourceProtocol {
    var metricsPublisher: AnyPublisher<ScanningMetrics, Never> { get }
    func startMetricsCollection()
    func stopMetricsCollection()
}

/// Visualization data source protocol
protocol VisualizationDataSourceProtocol {
    var visualizationPublisher: AnyPublisher<VisualizationData, Never> { get }
    func updateVisualization(_ data: VisualizationData)
}

// MARK: - Component Protocols

/// Design system protocol
protocol DesignSystemProtocol {
    func initialize(theme: UITheme) async
    func updateTheme(_ theme: UITheme) async
    func getColors(for theme: UITheme) -> ThemeColors
    func getFonts(for theme: UITheme) -> ThemeFonts
    func getSpacing(for theme: UITheme) -> ThemeSpacing
}

/// Data visualizer protocol
protocol DataVisualizerProtocol {
    func initialize(configuration: AdvancedUIManager.UIConfiguration) async
    func updateMetrics(_ metrics: RealTimeMetrics) async
    func updateProgress(_ progress: ScanningProgress) async
    func renderVisualization(_ data: VisualizationData) async
    func updateActiveVisualizations() async
    func enableRealTimeUpdates()
    func disableRealTimeUpdates()
}

/// Interaction manager protocol
protocol InteractionManagerProtocol {
    var averageLatency: TimeInterval { get }
    func initialize() async
    func processInteraction(_ interaction: UserInteraction) async -> InteractionResult
}

/// Animation engine protocol
protocol AnimationEngineProtocol {
    var performanceMetrics: AnimationPerformanceMetrics { get }
    var smoothnessScore: Float { get }
    func initialize() async
    func animateTransition(from: InterfaceMode, to: InterfaceMode, duration: Double) async
    func animateThemeChange(to theme: UITheme, duration: Double) async
    func animateViewAppearance(_ view: ViewType, duration: Double) async
    func animateViewDisappearance(_ view: ViewType, duration: Double) async
    func animateTapFeedback(at location: CGPoint) async
    func animateGestureFeedback(for gestureType: GestureType?) async
    func animateVoiceFeedback() async
    func updateAnimations() async
}

// MARK: - Theme Components

/// Theme colors
struct ThemeColors: Codable {
    let primary: Color
    let secondary: Color
    let background: Color
    let surface: Color
    let onPrimary: Color
    let onSecondary: Color
    let onBackground: Color
    let onSurface: Color
    let accent: Color
    let error: Color
    let warning: Color
    let success: Color
}

/// Theme fonts
struct ThemeFonts: Codable {
    let headline: String
    let title: String
    let body: String
    let caption: String
    let button: String
}

/// Theme spacing
struct ThemeSpacing: Codable {
    let extraSmall: CGFloat
    let small: CGFloat
    let medium: CGFloat
    let large: CGFloat
    let extraLarge: CGFloat
}

// MARK: - Performance Monitoring

/// UI performance monitor protocol
protocol UIPerformanceMonitorProtocol {
    var averageRenderTime: TimeInterval { get }
    func recordFrame()
    func getPerformanceMetrics() -> UIPerformanceMetrics
}

/// Frame rate monitor protocol
protocol FrameRateMonitorProtocol {
    var currentFrameRate: Float { get }
    func startMonitoring()
    func stopMonitoring()
}

/// Memory monitor protocol
protocol MemoryMonitorProtocol {
    var currentMemoryUsage: Float { get }
    func startMonitoring()
    func stopMonitoring()
}

// MARK: - Accessibility

/// Accessibility manager protocol
protocol AccessibilityManagerProtocol {
    func initialize() async
    func configureAccessibility(for view: ViewType)
    func announceChange(_ message: String)
    func enableVoiceOver()
    func disableVoiceOver()
}

// MARK: - Layout Management

/// Layout manager protocol
protocol LayoutManagerProtocol {
    func initialize() async
    func calculateLayout(for mode: InterfaceMode) -> LayoutConfiguration
    func updateLayout(_ configuration: LayoutConfiguration) async
}

/// Layout configuration
struct LayoutConfiguration: Codable {
    let mode: InterfaceMode
    let viewLayout: [ViewType: ViewLayout]
    let spacing: ThemeSpacing
    let margins: EdgeInsets
}

/// View layout
struct ViewLayout: Codable {
    let frame: CGRect
    let zIndex: Int
    let isVisible: Bool
    let animationDuration: Double
}

/// Edge insets
struct EdgeInsets: Codable {
    let top: CGFloat
    let leading: CGFloat
    let bottom: CGFloat
    let trailing: CGFloat

    init(top: CGFloat = 0, leading: CGFloat = 0, bottom: CGFloat = 0, trailing: CGFloat = 0) {
        self.top = top
        self.leading = leading
        self.bottom = bottom
        self.trailing = trailing
    }
}

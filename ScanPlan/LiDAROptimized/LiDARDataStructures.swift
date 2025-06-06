import Foundation
import ARKit
import simd
import CoreLocation

// MARK: - LiDAR Optimization Results

/// Comprehensive LiDAR optimization result
struct LiDAROptimizationResult: Identifiable, Codable {
    let id = UUID()
    let originalFrame: ARFrame
    let optimizedDepthData: OptimizedDepthData
    let calibrationResult: CalibrationResult
    let temperatureCompensation: ARFrame
    let motionCompensation: ARFrame
    let performanceOptimization: PerformanceOptimization
    let processingTime: TimeInterval
    let timestamp: Date
    let accuracy: Float // 0.0 - 1.0
    let qualityScore: Float // 0.0 - 1.0
    
    var depthPointCount: Int {
        return optimizedDepthData.pointCount
    }
    
    var optimizationEfficiency: Float {
        let pointsPerSecond = Float(depthPointCount) / Float(processingTime)
        return pointsPerSecond / 100_000.0 // Points per second in hundreds of thousands
    }
    
    var isHighQuality: Bool {
        return accuracy > 0.9 && qualityScore > 0.8
    }
    
    static func empty() -> LiDAROptimizationResult {
        return LiDAROptimizationResult(
            originalFrame: ARFrame(),
            optimizedDepthData: OptimizedDepthData.empty(),
            calibrationResult: CalibrationResult.default(),
            temperatureCompensation: ARFrame(),
            motionCompensation: ARFrame(),
            performanceOptimization: PerformanceOptimization.default(),
            processingTime: 0.0,
            timestamp: Date(),
            accuracy: 0.0,
            qualityScore: 0.0
        )
    }
}

/// Optimized depth data with enhanced processing
struct OptimizedDepthData: Identifiable, Codable {
    let id = UUID()
    let depthMap: DepthMap
    let confidenceMap: ConfidenceMap
    let noiseLevel: Float
    let temporalConsistency: Float
    let completeness: Float
    let effectiveResolution: Float
    let pointCount: Int
    let timestamp: Date
    
    var qualityLevel: DepthQuality {
        let overallScore = (1.0 - noiseLevel + temporalConsistency + completeness + effectiveResolution) / 4.0
        
        if overallScore > 0.9 {
            return .excellent
        } else if overallScore > 0.8 {
            return .good
        } else if overallScore > 0.7 {
            return .acceptable
        } else {
            return .poor
        }
    }
    
    static func empty() -> OptimizedDepthData {
        return OptimizedDepthData(
            depthMap: DepthMap.empty(),
            confidenceMap: ConfidenceMap.empty(),
            noiseLevel: 1.0,
            temporalConsistency: 0.0,
            completeness: 0.0,
            effectiveResolution: 0.0,
            pointCount: 0,
            timestamp: Date()
        )
    }
}

/// Enhanced depth map with optimization
struct DepthMap: Codable {
    let width: Int
    let height: Int
    let depthValues: [Float]
    let minDepth: Float
    let maxDepth: Float
    let averageDepth: Float
    
    var resolution: Float {
        return Float(width * height)
    }
    
    var depthRange: Float {
        return maxDepth - minDepth
    }
    
    static func empty() -> DepthMap {
        return DepthMap(
            width: 0,
            height: 0,
            depthValues: [],
            minDepth: 0.0,
            maxDepth: 0.0,
            averageDepth: 0.0
        )
    }
}

/// Confidence map for depth reliability
struct ConfidenceMap: Codable {
    let width: Int
    let height: Int
    let confidenceValues: [Float]
    let averageConfidence: Float
    let highConfidenceRatio: Float
    
    var reliabilityScore: Float {
        return averageConfidence * highConfidenceRatio
    }
    
    static func empty() -> ConfidenceMap {
        return ConfidenceMap(
            width: 0,
            height: 0,
            confidenceValues: [],
            averageConfidence: 0.0,
            highConfidenceRatio: 0.0
        )
    }
}

enum DepthQuality: String, CaseIterable, Codable {
    case excellent = "excellent"
    case good = "good"
    case acceptable = "acceptable"
    case poor = "poor"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var color: String {
        switch self {
        case .excellent: return "green"
        case .good: return "blue"
        case .acceptable: return "yellow"
        case .poor: return "red"
        }
    }
}

// MARK: - Calibration

/// Calibration result with hardware-specific parameters
struct CalibrationResult: Identifiable, Codable {
    let id = UUID()
    let calibrationType: CalibrationType
    let intrinsicParameters: IntrinsicParameters
    let extrinsicParameters: ExtrinsicParameters
    let distortionCorrection: DistortionCorrection
    let temperatureCompensation: TemperatureCompensation
    let accuracy: Float
    let timestamp: Date
    
    var isValid: Bool {
        return accuracy > 0.8
    }
    
    var calibrationQuality: CalibrationQuality {
        if accuracy > 0.95 {
            return .excellent
        } else if accuracy > 0.9 {
            return .good
        } else if accuracy > 0.8 {
            return .acceptable
        } else {
            return .poor
        }
    }
    
    static func `default`() -> CalibrationResult {
        return CalibrationResult(
            calibrationType: .factory,
            intrinsicParameters: IntrinsicParameters.default(),
            extrinsicParameters: ExtrinsicParameters.default(),
            distortionCorrection: DistortionCorrection.default(),
            temperatureCompensation: TemperatureCompensation.default(),
            accuracy: 0.8,
            timestamp: Date()
        )
    }
}

enum CalibrationType: String, CaseIterable, Codable {
    case factory = "factory"
    case environmental = "environmental"
    case adaptive = "adaptive"
    case userCalibrated = "user_calibrated"
    
    var displayName: String {
        switch self {
        case .factory: return "Factory"
        case .environmental: return "Environmental"
        case .adaptive: return "Adaptive"
        case .userCalibrated: return "User Calibrated"
        }
    }
}

enum CalibrationQuality: String, CaseIterable, Codable {
    case excellent = "excellent"
    case good = "good"
    case acceptable = "acceptable"
    case poor = "poor"
    
    var displayName: String {
        return rawValue.capitalized
    }
}

/// Camera intrinsic parameters
struct IntrinsicParameters: Codable {
    let focalLength: simd_float2
    let principalPoint: simd_float2
    let imageResolution: simd_int2
    
    static func `default`() -> IntrinsicParameters {
        return IntrinsicParameters(
            focalLength: simd_float2(1000.0, 1000.0),
            principalPoint: simd_float2(320.0, 240.0),
            imageResolution: simd_int2(640, 480)
        )
    }
}

/// Camera extrinsic parameters
struct ExtrinsicParameters: Codable {
    let rotation: simd_float3x3
    let translation: simd_float3
    
    static func `default`() -> ExtrinsicParameters {
        return ExtrinsicParameters(
            rotation: matrix_identity_float3x3,
            translation: simd_float3(0, 0, 0)
        )
    }
}

/// Distortion correction parameters
struct DistortionCorrection: Codable {
    let radialDistortion: simd_float3
    let tangentialDistortion: simd_float2
    let correctionStrength: Float
    
    static func `default`() -> DistortionCorrection {
        return DistortionCorrection(
            radialDistortion: simd_float3(0, 0, 0),
            tangentialDistortion: simd_float2(0, 0),
            correctionStrength: 1.0
        )
    }
}

/// Temperature compensation parameters
struct TemperatureCompensation: Codable {
    let referenceTemperature: Float
    let thermalCoefficients: [Float]
    let compensationStrength: Float
    
    static func `default`() -> TemperatureCompensation {
        return TemperatureCompensation(
            referenceTemperature: 25.0,
            thermalCoefficients: [0.0, 0.0, 0.0],
            compensationStrength: 1.0
        )
    }
}

// MARK: - Hardware Detection

/// Device model detection
enum DeviceModel: String, CaseIterable, Codable {
    case iPhone12Pro = "iPhone12Pro"
    case iPhone13Pro = "iPhone13Pro"
    case iPhone14Pro = "iPhone14Pro"
    case iPhone15Pro = "iPhone15Pro"
    case iPadPro11_3rd = "iPadPro11_3rd"
    case iPadPro11_4th = "iPadPro11_4th"
    case iPadPro12_5th = "iPadPro12_5th"
    case iPadPro12_6th = "iPadPro12_6th"
    case unknown = "unknown"
    
    var displayName: String {
        switch self {
        case .iPhone12Pro: return "iPhone 12 Pro"
        case .iPhone13Pro: return "iPhone 13 Pro"
        case .iPhone14Pro: return "iPhone 14 Pro"
        case .iPhone15Pro: return "iPhone 15 Pro"
        case .iPadPro11_3rd: return "iPad Pro 11\" (3rd gen)"
        case .iPadPro11_4th: return "iPad Pro 11\" (4th gen)"
        case .iPadPro12_5th: return "iPad Pro 12.9\" (5th gen)"
        case .iPadPro12_6th: return "iPad Pro 12.9\" (6th gen)"
        case .unknown: return "Unknown Device"
        }
    }
    
    var lidarGeneration: LiDARGeneration {
        switch self {
        case .iPhone12Pro, .iPadPro11_3rd, .iPadPro12_5th:
            return .gen1
        case .iPhone13Pro, .iPhone14Pro, .iPadPro11_4th, .iPadPro12_6th:
            return .gen2
        case .iPhone15Pro:
            return .gen3
        case .unknown:
            return .unknown
        }
    }
}

enum LiDARGeneration: String, CaseIterable, Codable {
    case gen1 = "gen1"
    case gen2 = "gen2"
    case gen3 = "gen3"
    case unknown = "unknown"
    
    var displayName: String {
        switch self {
        case .gen1: return "1st Generation"
        case .gen2: return "2nd Generation"
        case .gen3: return "3rd Generation"
        case .unknown: return "Unknown"
        }
    }
    
    var maxRange: Float {
        switch self {
        case .gen1: return 5.0
        case .gen2: return 5.0
        case .gen3: return 6.0
        case .unknown: return 3.0
        }
    }
    
    var accuracy: Float {
        switch self {
        case .gen1: return 0.01 // 1cm
        case .gen2: return 0.005 // 5mm
        case .gen3: return 0.002 // 2mm
        case .unknown: return 0.05 // 5cm
        }
    }
}

/// LiDAR hardware capabilities
struct LiDARCapabilities: Codable {
    let generation: LiDARGeneration
    let maxRange: Float
    let minRange: Float
    let accuracy: Float
    let frameRate: Float
    let resolution: simd_int2
    let fieldOfView: Float
    let supportedModes: [LiDARMode]
    
    init() {
        self.generation = .unknown
        self.maxRange = 5.0
        self.minRange = 0.1
        self.accuracy = 0.01
        self.frameRate = 60.0
        self.resolution = simd_int2(256, 192)
        self.fieldOfView = 70.0
        self.supportedModes = [.standard]
    }
    
    var description: String {
        return "\(generation.displayName) - Range: \(minRange)m-\(maxRange)m, Accuracy: \(accuracy * 1000)mm"
    }
}

enum LiDARMode: String, CaseIterable, Codable {
    case standard = "standard"
    case highAccuracy = "high_accuracy"
    case longRange = "long_range"
    case lowPower = "low_power"
    
    var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .highAccuracy: return "High Accuracy"
        case .longRange: return "Long Range"
        case .lowPower: return "Low Power"
        }
    }
}

/// Hardware performance profile
struct HardwareProfile: Codable {
    let deviceModel: DeviceModel
    let lidarCapabilities: LiDARCapabilities
    let thermalCharacteristics: ThermalCharacteristics
    let performanceMetrics: HardwarePerformanceMetrics
    let optimizationParameters: OptimizationParameters
    
    init() {
        self.deviceModel = .unknown
        self.lidarCapabilities = LiDARCapabilities()
        self.thermalCharacteristics = ThermalCharacteristics()
        self.performanceMetrics = HardwarePerformanceMetrics()
        self.optimizationParameters = OptimizationParameters()
    }
}

/// Thermal characteristics of the device
struct ThermalCharacteristics: Codable {
    let operatingTemperatureRange: ClosedRange<Float>
    let optimalTemperature: Float
    let thermalThrottlingThreshold: Float
    let coolingRate: Float
    
    init() {
        self.operatingTemperatureRange = 0.0...45.0
        self.optimalTemperature = 25.0
        self.thermalThrottlingThreshold = 40.0
        self.coolingRate = 0.5
    }
}

/// Hardware performance metrics
struct HardwarePerformanceMetrics: Codable {
    let maxProcessingRate: Float
    let averageLatency: TimeInterval
    let powerConsumption: Float
    let memoryUsage: Float
    
    init() {
        self.maxProcessingRate = 60.0
        self.averageLatency = 0.016
        self.powerConsumption = 2.5
        self.memoryUsage = 128.0
    }
}

/// Optimization parameters for hardware
struct OptimizationParameters: Codable {
    let adaptiveFiltering: Bool
    let temperatureCompensation: Bool
    let motionCompensation: Bool
    let noiseReduction: Float
    let qualityThreshold: Float
    
    init() {
        self.adaptiveFiltering = true
        self.temperatureCompensation = true
        self.motionCompensation = true
        self.noiseReduction = 0.8
        self.qualityThreshold = 0.7
    }
}

// MARK: - Environmental Conditions

/// Environmental conditions affecting LiDAR performance
struct EnvironmentalConditions: Codable {
    let temperature: Float
    let lightingConditions: LightingConditions
    let motionLevel: MotionLevel
    let ambientNoise: Float
    let timestamp: Date
    
    init() {
        self.temperature = 25.0
        self.lightingConditions = LightingConditions()
        self.motionLevel = .low
        self.ambientNoise = 0.1
        self.timestamp = Date()
    }
    
    init(temperature: Float, lightingConditions: LightingConditions, motionLevel: MotionLevel, ambientNoise: Float, timestamp: Date) {
        self.temperature = temperature
        self.lightingConditions = lightingConditions
        self.motionLevel = motionLevel
        self.ambientNoise = ambientNoise
        self.timestamp = timestamp
    }
}

/// Lighting conditions assessment
struct LightingConditions: Codable {
    let brightness: Float // 0.0 - 1.0
    let contrast: Float // 0.0 - 1.0
    let uniformity: Float // 0.0 - 1.0
    let colorTemperature: Float // Kelvin
    
    init() {
        self.brightness = 0.5
        self.contrast = 0.5
        self.uniformity = 0.5
        self.colorTemperature = 5500.0
    }
    
    init(brightness: Float, contrast: Float, uniformity: Float, colorTemperature: Float) {
        self.brightness = brightness
        self.contrast = contrast
        self.uniformity = uniformity
        self.colorTemperature = colorTemperature
    }
    
    var lightingQuality: LightingQuality {
        let overallScore = (brightness + contrast + uniformity) / 3.0
        
        if overallScore > 0.8 {
            return .excellent
        } else if overallScore > 0.6 {
            return .good
        } else if overallScore > 0.4 {
            return .acceptable
        } else {
            return .poor
        }
    }
}

enum LightingQuality: String, CaseIterable, Codable {
    case excellent = "excellent"
    case good = "good"
    case acceptable = "acceptable"
    case poor = "poor"
    
    var displayName: String {
        return rawValue.capitalized
    }
}

enum MotionLevel: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case unknown = "unknown"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var compensationStrength: Float {
        switch self {
        case .low: return 0.1
        case .medium: return 0.5
        case .high: return 1.0
        case .unknown: return 0.3
        }
    }
}

enum EnvironmentType: String, CaseIterable, Codable {
    case indoor = "indoor"
    case outdoor = "outdoor"
    case lowLight = "low_light"
    case brightLight = "bright_light"
    case highMotion = "high_motion"
    case static = "static"

    var displayName: String {
        switch self {
        case .indoor: return "Indoor"
        case .outdoor: return "Outdoor"
        case .lowLight: return "Low Light"
        case .brightLight: return "Bright Light"
        case .highMotion: return "High Motion"
        case .static: return "Static"
        }
    }
}

// MARK: - Performance Optimization

/// Performance optimization result
struct PerformanceOptimization: Codable {
    let optimizationType: OptimizationType
    let parameters: OptimizationParameters
    let performanceGain: Float
    let qualityImpact: Float
    let powerSavings: Float
    let timestamp: Date

    var isEffective: Bool {
        return performanceGain > 0.1 && qualityImpact > -0.1
    }

    static func `default`() -> PerformanceOptimization {
        return PerformanceOptimization(
            optimizationType: .balanced,
            parameters: OptimizationParameters(),
            performanceGain: 0.0,
            qualityImpact: 0.0,
            powerSavings: 0.0,
            timestamp: Date()
        )
    }
}

enum OptimizationType: String, CaseIterable, Codable {
    case performance = "performance"
    case quality = "quality"
    case balanced = "balanced"
    case powerSaving = "power_saving"

    var displayName: String {
        switch self {
        case .performance: return "Performance"
        case .quality: return "Quality"
        case .balanced: return "Balanced"
        case .powerSaving: return "Power Saving"
        }
    }
}

// MARK: - Status and Health

/// LiDAR sensor status
struct LiDARSensorStatus: Codable {
    let calibrationState: CalibrationState
    let accuracy: Float
    let temperature: Float
    let processingLoad: LiDARProcessingLoad
    let hardwareHealth: HardwareHealth
    let lastOptimization: Date?

    var overallStatus: SensorStatus {
        if hardwareHealth == .healthy && calibrationState.isCalibrated && accuracy > 0.9 {
            return .optimal
        } else if hardwareHealth != .critical && calibrationState.isCalibrated && accuracy > 0.7 {
            return .good
        } else if hardwareHealth != .critical && accuracy > 0.5 {
            return .acceptable
        } else {
            return .poor
        }
    }
}

enum CalibrationState: String, CaseIterable, Codable {
    case uncalibrated = "uncalibrated"
    case needsCalibration = "needs_calibration"
    case partiallyCalibrated = "partially_calibrated"
    case calibrated = "calibrated"
    case wellCalibrated = "well_calibrated"
    case excellentlyCalibrated = "excellently_calibrated"

    var displayName: String {
        switch self {
        case .uncalibrated: return "Uncalibrated"
        case .needsCalibration: return "Needs Calibration"
        case .partiallyCalibrated: return "Partially Calibrated"
        case .calibrated: return "Calibrated"
        case .wellCalibrated: return "Well Calibrated"
        case .excellentlyCalibrated: return "Excellently Calibrated"
        }
    }

    var isCalibrated: Bool {
        switch self {
        case .calibrated, .wellCalibrated, .excellentlyCalibrated:
            return true
        default:
            return false
        }
    }

    var color: String {
        switch self {
        case .excellentlyCalibrated: return "green"
        case .wellCalibrated: return "blue"
        case .calibrated: return "yellow"
        case .partiallyCalibrated: return "orange"
        case .needsCalibration, .uncalibrated: return "red"
        }
    }
}

enum SensorStatus: String, CaseIterable, Codable {
    case optimal = "optimal"
    case good = "good"
    case acceptable = "acceptable"
    case poor = "poor"

    var displayName: String {
        return rawValue.capitalized
    }

    var color: String {
        switch self {
        case .optimal: return "green"
        case .good: return "blue"
        case .acceptable: return "yellow"
        case .poor: return "red"
        }
    }
}

enum HardwareHealth: String, CaseIterable, Codable {
    case healthy = "healthy"
    case caution = "caution"
    case warning = "warning"
    case critical = "critical"

    var displayName: String {
        return rawValue.capitalized
    }

    var color: String {
        switch self {
        case .healthy: return "green"
        case .caution: return "yellow"
        case .warning: return "orange"
        case .critical: return "red"
        }
    }
}

enum LiDARProcessingLoad: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"

    var displayName: String {
        return rawValue.capitalized
    }

    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "yellow"
        case .high: return "red"
        }
    }
}

// MARK: - Performance Metrics

/// LiDAR performance metrics
struct LiDARMetrics: Codable {
    let averageProcessingTime: TimeInterval
    let averageAccuracy: Float
    let averageQuality: Float
    let totalOptimizations: Int
    let optimizationFrequency: Double
    let calibrationState: CalibrationState
    let hardwareHealth: HardwareHealth

    init() {
        self.averageProcessingTime = 0.0
        self.averageAccuracy = 0.0
        self.averageQuality = 0.0
        self.totalOptimizations = 0
        self.optimizationFrequency = 0.0
        self.calibrationState = .uncalibrated
        self.hardwareHealth = .healthy
    }

    init(averageProcessingTime: TimeInterval, averageAccuracy: Float, averageQuality: Float,
         totalOptimizations: Int, optimizationFrequency: Double, calibrationState: CalibrationState,
         hardwareHealth: HardwareHealth) {
        self.averageProcessingTime = averageProcessingTime
        self.averageAccuracy = averageAccuracy
        self.averageQuality = averageQuality
        self.totalOptimizations = totalOptimizations
        self.optimizationFrequency = optimizationFrequency
        self.calibrationState = calibrationState
        self.hardwareHealth = hardwareHealth
    }

    var performanceLevel: PerformanceLevel {
        if averageProcessingTime < 0.016 && averageAccuracy > 0.95 && averageQuality > 0.9 {
            return .excellent
        } else if averageProcessingTime < 0.033 && averageAccuracy > 0.9 && averageQuality > 0.8 {
            return .good
        } else if averageProcessingTime < 0.066 && averageAccuracy > 0.8 && averageQuality > 0.7 {
            return .acceptable
        } else {
            return .poor
        }
    }
}

/// LiDAR performance metric
struct LiDARPerformanceMetric: Codable {
    let metricType: LiDARMetricType
    let value: Float
    let timestamp: Date
}

enum LiDARMetricType: String, CaseIterable, Codable {
    case processingTime = "processing_time"
    case accuracy = "accuracy"
    case quality = "quality"
    case temperature = "temperature"
    case calibrationDrift = "calibration_drift"

    var displayName: String {
        switch self {
        case .processingTime: return "Processing Time"
        case .accuracy: return "Accuracy"
        case .quality: return "Quality"
        case .temperature: return "Temperature"
        case .calibrationDrift: return "Calibration Drift"
        }
    }

    var unit: String {
        switch self {
        case .processingTime: return "ms"
        case .accuracy: return "%"
        case .quality: return "%"
        case .temperature: return "°C"
        case .calibrationDrift: return "mm"
        }
    }
}

// MARK: - History Tracking

/// Temperature reading for history
struct TemperatureReading: Codable {
    let temperature: Float
    let timestamp: Date
}

/// Motion reading for history
struct MotionReading: Codable {
    let motionLevel: MotionLevel
    let timestamp: Date
}

/// Calibration frame for history tracking
struct CalibrationFrame: Codable {
    let result: LiDAROptimizationResult
    let timestamp: Date

    var accuracy: Float {
        return result.accuracy
    }

    var qualityScore: Float {
        return result.qualityScore
    }

    var processingTime: TimeInterval {
        return result.processingTime
    }
}

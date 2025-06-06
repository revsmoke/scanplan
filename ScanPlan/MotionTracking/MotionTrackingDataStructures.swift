import Foundation
import CoreMotion
import ARKit
import simd

// MARK: - Motion Tracking Data Structures

/// Motion frame containing comprehensive motion data
struct MotionFrame: Codable {
    let timestamp: TimeInterval
    let attitude: CMAttitude
    let rotationRate: CMRotationRate
    let userAcceleration: CMAcceleration
    let gravity: CMAcceleration
    let magneticField: CMMagneticField
    
    // Derived properties
    var motionMagnitude: Float {
        let accel = simd_float3(Float(userAcceleration.x), Float(userAcceleration.y), Float(userAcceleration.z))
        let rotation = simd_float3(Float(rotationRate.x), Float(rotationRate.y), Float(rotationRate.z))
        return simd_length(accel) + simd_length(rotation) * 0.1
    }
    
    var isStable: Bool {
        return motionMagnitude < 0.05 // 5cm threshold
    }
    
    // Custom coding for CoreMotion types
    enum CodingKeys: String, CodingKey {
        case timestamp
        case attitudeRoll, attitudePitch, attitudeYaw
        case rotationRateX, rotationRateY, rotationRateZ
        case userAccelX, userAccelY, userAccelZ
        case gravityX, gravityY, gravityZ
        case magneticFieldX, magneticFieldY, magneticFieldZ, magneticFieldAccuracy
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(attitude.roll, forKey: .attitudeRoll)
        try container.encode(attitude.pitch, forKey: .attitudePitch)
        try container.encode(attitude.yaw, forKey: .attitudeYaw)
        try container.encode(rotationRate.x, forKey: .rotationRateX)
        try container.encode(rotationRate.y, forKey: .rotationRateY)
        try container.encode(rotationRate.z, forKey: .rotationRateZ)
        try container.encode(userAcceleration.x, forKey: .userAccelX)
        try container.encode(userAcceleration.y, forKey: .userAccelY)
        try container.encode(userAcceleration.z, forKey: .userAccelZ)
        try container.encode(gravity.x, forKey: .gravityX)
        try container.encode(gravity.y, forKey: .gravityY)
        try container.encode(gravity.z, forKey: .gravityZ)
        try container.encode(magneticField.field.x, forKey: .magneticFieldX)
        try container.encode(magneticField.field.y, forKey: .magneticFieldY)
        try container.encode(magneticField.field.z, forKey: .magneticFieldZ)
        try container.encode(magneticField.accuracy.rawValue, forKey: .magneticFieldAccuracy)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        timestamp = try container.decode(TimeInterval.self, forKey: .timestamp)
        
        let roll = try container.decode(Double.self, forKey: .attitudeRoll)
        let pitch = try container.decode(Double.self, forKey: .attitudePitch)
        let yaw = try container.decode(Double.self, forKey: .attitudeYaw)
        attitude = CMAttitude()
        // Note: CMAttitude cannot be easily reconstructed from roll/pitch/yaw
        
        rotationRate = CMRotationRate(
            x: try container.decode(Double.self, forKey: .rotationRateX),
            y: try container.decode(Double.self, forKey: .rotationRateY),
            z: try container.decode(Double.self, forKey: .rotationRateZ)
        )
        
        userAcceleration = CMAcceleration(
            x: try container.decode(Double.self, forKey: .userAccelX),
            y: try container.decode(Double.self, forKey: .userAccelY),
            z: try container.decode(Double.self, forKey: .userAccelZ)
        )
        
        gravity = CMAcceleration(
            x: try container.decode(Double.self, forKey: .gravityX),
            y: try container.decode(Double.self, forKey: .gravityY),
            z: try container.decode(Double.self, forKey: .gravityZ)
        )
        
        let fieldX = try container.decode(Double.self, forKey: .magneticFieldX)
        let fieldY = try container.decode(Double.self, forKey: .magneticFieldY)
        let fieldZ = try container.decode(Double.self, forKey: .magneticFieldZ)
        let accuracyRaw = try container.decode(Int.self, forKey: .magneticFieldAccuracy)
        
        magneticField = CMMagneticField(
            field: CMMagneticFieldVector(x: fieldX, y: fieldY, z: fieldZ),
            accuracy: CMMagneticFieldCalibrationAccuracy(rawValue: accuracyRaw) ?? .uncalibrated
        )
    }
    
    init(timestamp: TimeInterval, attitude: CMAttitude, rotationRate: CMRotationRate,
         userAcceleration: CMAcceleration, gravity: CMAcceleration, magneticField: CMMagneticField) {
        self.timestamp = timestamp
        self.attitude = attitude
        self.rotationRate = rotationRate
        self.userAcceleration = userAcceleration
        self.gravity = gravity
        self.magneticField = magneticField
    }
    
    static func `default`() -> MotionFrame {
        return MotionFrame(
            timestamp: Date().timeIntervalSince1970,
            attitude: CMAttitude(),
            rotationRate: CMRotationRate(x: 0, y: 0, z: 0),
            userAcceleration: CMAcceleration(x: 0, y: 0, z: 0),
            gravity: CMAcceleration(x: 0, y: -1, z: 0),
            magneticField: CMMagneticField(
                field: CMMagneticFieldVector(x: 0, y: 0, z: 0),
                accuracy: .uncalibrated
            )
        )
    }
}

/// Motion state classification
enum MotionState: String, CaseIterable, Codable {
    case stable = "stable"
    case lowMotion = "low_motion"
    case highMotion = "high_motion"
    case unknown = "unknown"
    
    var displayName: String {
        switch self {
        case .stable: return "Stable"
        case .lowMotion: return "Low Motion"
        case .highMotion: return "High Motion"
        case .unknown: return "Unknown"
        }
    }
    
    var color: String {
        switch self {
        case .stable: return "green"
        case .lowMotion: return "yellow"
        case .highMotion: return "red"
        case .unknown: return "gray"
        }
    }
}

/// Tracking quality assessment
enum TrackingQuality: String, CaseIterable, Codable {
    case excellent = "excellent"
    case good = "good"
    case acceptable = "acceptable"
    case poor = "poor"
    case unknown = "unknown"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var color: String {
        switch self {
        case .excellent: return "green"
        case .good: return "blue"
        case .acceptable: return "yellow"
        case .poor: return "red"
        case .unknown: return "gray"
        }
    }
    
    var meetsRequirements: Bool {
        switch self {
        case .excellent, .good, .acceptable: return true
        case .poor, .unknown: return false
        }
    }
}

/// Motion stability assessment
struct MotionStability: Codable {
    let isStable: Bool
    let confidence: Float // 0.0 - 1.0
    let motionMagnitude: Float
    
    var stabilityLevel: StabilityLevel {
        if confidence > 0.9 {
            return .excellent
        } else if confidence > 0.7 {
            return .good
        } else if confidence > 0.5 {
            return .acceptable
        } else {
            return .poor
        }
    }
}

enum StabilityLevel: String, CaseIterable {
    case excellent = "excellent"
    case good = "good"
    case acceptable = "acceptable"
    case poor = "poor"
    
    var displayName: String {
        return rawValue.capitalized
    }
}

// MARK: - Measurement and Compensation

/// Original measurement data
struct Measurement: Codable {
    let id: UUID = UUID()
    let value: Float // Measurement value
    let distance: Float // Distance from device
    let position: simd_float3 // 3D position
    let timestamp: TimeInterval
    let type: MeasurementType
    
    var accuracy: Float {
        // Base accuracy depends on measurement type
        switch type {
        case .distance: return 0.01 // 1cm
        case .area: return 0.02 // 2cm²
        case .volume: return 0.05 // 5cm³
        case .angle: return 0.1 // 0.1 degree
        }
    }
}

enum MeasurementType: String, CaseIterable, Codable {
    case distance = "distance"
    case area = "area"
    case volume = "volume"
    case angle = "angle"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var unit: String {
        switch self {
        case .distance: return "m"
        case .area: return "m²"
        case .volume: return "m³"
        case .angle: return "°"
        }
    }
}

/// Compensated measurement value
struct CompensatedValue: Codable {
    let value: Float
    let compensationType: CompensationType
    let confidence: Float // 0.0 - 1.0
    
    var isHighConfidence: Bool {
        return confidence > 0.8
    }
}

enum CompensationType: String, CaseIterable, Codable {
    case linear = "linear"
    case angular = "angular"
    case predictive = "predictive"
    case adaptive = "adaptive"
    
    var displayName: String {
        switch self {
        case .linear: return "Linear Compensation"
        case .angular: return "Angular Compensation"
        case .predictive: return "Predictive Compensation"
        case .adaptive: return "Adaptive Compensation"
        }
    }
}

/// Complete compensated measurement
struct CompensatedMeasurement: Identifiable, Codable {
    let id = UUID()
    let original: Measurement
    let compensated: CompensatedValue
    let motionFrame: MotionFrame
    let validationResult: ValidationResult
    let timestamp: Date
    let processingTime: TimeInterval
    
    var improvementRatio: Float {
        guard original.value != 0 else { return 0 }
        return abs(compensated.value - original.value) / original.value
    }
    
    var isSignificantImprovement: Bool {
        return improvementRatio > 0.01 // 1% improvement threshold
    }
}

// MARK: - Validation and Assessment

/// Validation result for compensation
struct ValidationResult: Codable {
    let isValid: Bool
    let effectiveness: Float // 0.0 - 1.0
    let accuracy: AccuracyAssessment
    let confidence: Float // 0.0 - 1.0
    let timestamp: Date
    
    var validationLevel: ValidationLevel {
        if isValid && confidence > 0.9 {
            return .excellent
        } else if isValid && confidence > 0.7 {
            return .good
        } else if isValid {
            return .acceptable
        } else {
            return .failed
        }
    }
}

enum ValidationLevel: String, CaseIterable {
    case excellent = "excellent"
    case good = "good"
    case acceptable = "acceptable"
    case failed = "failed"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var color: String {
        switch self {
        case .excellent: return "green"
        case .good: return "blue"
        case .acceptable: return "yellow"
        case .failed: return "red"
        }
    }
}

/// Accuracy assessment for measurements
struct AccuracyAssessment: Codable {
    let estimatedAccuracy: Float // Estimated accuracy in meters
    let confidence: Float // 0.0 - 1.0
    let meetsRequirements: Bool
    let accuracyLevel: AccuracyLevel
    
    var accuracyInMillimeters: Float {
        return estimatedAccuracy * 1000
    }
}

enum AccuracyLevel: String, CaseIterable, Codable {
    case subMillimeter = "sub_millimeter" // <1mm
    case millimeter = "millimeter" // 1-2mm
    case centimeter = "centimeter" // 1-5cm
    case decimeter = "decimeter" // >5cm
    
    var displayName: String {
        switch self {
        case .subMillimeter: return "Sub-Millimeter"
        case .millimeter: return "Millimeter"
        case .centimeter: return "Centimeter"
        case .decimeter: return "Decimeter"
        }
    }
    
    var range: ClosedRange<Float> {
        switch self {
        case .subMillimeter: return 0.0...0.001
        case .millimeter: return 0.001...0.002
        case .centimeter: return 0.01...0.05
        case .decimeter: return 0.05...1.0
        }
    }
}

// MARK: - Prediction and Tracking

/// Predicted motion for proactive compensation
struct PredictedMotion: Codable {
    let predictedVelocity: simd_float3
    let predictedAngularVelocity: simd_float3
    let confidence: Float // 0.0 - 1.0
    let timeHorizon: TimeInterval
    let predictionMethod: PredictionMethod
    
    var motionMagnitude: Float {
        return simd_length(predictedVelocity) + simd_length(predictedAngularVelocity) * 0.1
    }
}

enum PredictionMethod: String, CaseIterable, Codable {
    case linear = "linear"
    case kalman = "kalman"
    case neuralNetwork = "neural_network"
    case hybrid = "hybrid"
    
    var displayName: String {
        switch self {
        case .linear: return "Linear Prediction"
        case .kalman: return "Kalman Filter"
        case .neuralNetwork: return "Neural Network"
        case .hybrid: return "Hybrid Method"
        }
    }
}

/// Tracking validation result
struct TrackingValidationResult: Codable {
    let isValid: Bool
    let trackingQuality: TrackingQuality
    let motionConsistency: Float // 0.0 - 1.0
    let temporalStability: Float // 0.0 - 1.0
    let spatialAccuracy: Float // Estimated accuracy in meters
    let validationIssues: [TrackingIssue]
    let timestamp: Date
    
    var overallScore: Float {
        return (motionConsistency + temporalStability + (1.0 - spatialAccuracy * 100)) / 3.0
    }
}

struct TrackingIssue: Codable {
    let type: TrackingIssueType
    let severity: IssueSeverity
    let description: String
    let recommendation: String
}

enum TrackingIssueType: String, CaseIterable, Codable {
    case excessiveMotion = "excessive_motion"
    case poorLighting = "poor_lighting"
    case featureLoss = "feature_loss"
    case calibrationDrift = "calibration_drift"
    case sensorNoise = "sensor_noise"
}

enum IssueSeverity: String, CaseIterable, Codable {
    case critical = "critical"
    case major = "major"
    case minor = "minor"
    case warning = "warning"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var color: String {
        switch self {
        case .critical: return "red"
        case .major: return "orange"
        case .minor: return "yellow"
        case .warning: return "blue"
        }
    }
}

// MARK: - Performance Metrics

/// Compensation performance metrics
struct CompensationMetrics: Codable {
    let averageEffectiveness: Float
    let averageConfidence: Float
    let validationSuccessRate: Float
    let totalValidations: Int
    let averageProcessingTime: TimeInterval
    
    init() {
        self.averageEffectiveness = 0.0
        self.averageConfidence = 0.0
        self.validationSuccessRate = 0.0
        self.totalValidations = 0
        self.averageProcessingTime = 0.0
    }
    
    init(averageEffectiveness: Float, averageConfidence: Float, validationSuccessRate: Float,
         totalValidations: Int, averageProcessingTime: TimeInterval) {
        self.averageEffectiveness = averageEffectiveness
        self.averageConfidence = averageConfidence
        self.validationSuccessRate = validationSuccessRate
        self.totalValidations = totalValidations
        self.averageProcessingTime = averageProcessingTime
    }
    
    var performanceLevel: PerformanceLevel {
        let overallScore = (averageEffectiveness + averageConfidence + validationSuccessRate) / 3.0
        
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
}

enum PerformanceLevel: String, CaseIterable {
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

/// Compensation frame for history tracking
struct CompensationFrame: Codable {
    let timestamp: Date
    let originalMeasurement: Measurement
    let compensatedValue: CompensatedValue
    let motionFrame: MotionFrame
    let processingTime: TimeInterval
    
    var compensationRatio: Float {
        guard originalMeasurement.value != 0 else { return 0 }
        return abs(compensatedValue.value - originalMeasurement.value) / originalMeasurement.value
    }
}

// MARK: - Supporting Classes (Placeholder)

class TrackingValidator {
    func startValidation() {
        print("🎯 Tracking validator started")
    }
    
    func stopValidation() {
        print("🎯 Tracking validator stopped")
    }
    
    func validateTracking(_ frame: ARFrame, motionHistory: [MotionFrame]) async -> TrackingValidationResult {
        // Placeholder implementation
        return TrackingValidationResult(
            isValid: true,
            trackingQuality: .good,
            motionConsistency: 0.85,
            temporalStability: 0.9,
            spatialAccuracy: 0.005,
            validationIssues: [],
            timestamp: Date()
        )
    }
}

class MotionPredictor {
    func startPrediction() {
        print("🔮 Motion predictor started")
    }
    
    func stopPrediction() {
        print("🔮 Motion predictor stopped")
    }
    
    func predictMotion(timeAhead: TimeInterval, history: [MotionFrame]) async -> PredictedMotion? {
        guard !history.isEmpty else { return nil }
        
        // Placeholder implementation
        return PredictedMotion(
            predictedVelocity: simd_float3(0.01, 0.01, 0.01),
            predictedAngularVelocity: simd_float3(0.001, 0.001, 0.001),
            confidence: 0.8,
            timeHorizon: timeAhead,
            predictionMethod: .linear
        )
    }
}

class CompensationFilter {
    func applyAdaptiveFiltering(_ value: CompensatedValue, motionFrame: MotionFrame) async -> CompensatedValue {
        // Placeholder implementation
        return value
    }
}

class AccuracyAssessor {
    func assessCompensationEffectiveness(original: Measurement, compensated: CompensatedValue, motionFrame: MotionFrame) async -> Float {
        // Placeholder implementation
        return 0.85
    }
    
    func assessMeasurementAccuracy(compensated: CompensatedValue, motionFrame: MotionFrame) async -> AccuracyAssessment {
        // Placeholder implementation
        return AccuracyAssessment(
            estimatedAccuracy: 0.002,
            confidence: 0.9,
            meetsRequirements: true,
            accuracyLevel: .millimeter
        )
    }
}

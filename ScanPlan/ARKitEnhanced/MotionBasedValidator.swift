import Foundation
import ARKit
import CoreMotion
import simd

/// Motion-based validator for plane measurements using device motion and ARKit tracking
/// Implements validation algorithms to ensure measurement accuracy through motion analysis
class MotionBasedValidator {
    
    // MARK: - Configuration
    
    struct ValidationConfiguration {
        let motionThreshold: Float = 0.1 // 10cm/s maximum motion for validation
        let stabilityDuration: TimeInterval = 2.0 // 2 seconds of stability required
        let confidenceThreshold: Float = 0.8
        let enableDeviceMotion: Bool = true
        let enableVisualInertial: Bool = true
        let maxValidationTime: TimeInterval = 10.0
    }
    
    private let configuration = ValidationConfiguration()
    
    // MARK: - Motion Tracking
    
    private let motionManager = CMMotionManager()
    private var motionData: [CMDeviceMotion] = []
    private var validationSessions: [UUID: ValidationSession] = []
    
    // MARK: - Initialization
    
    init() {
        setupMotionTracking()
    }
    
    deinit {
        motionManager.stopDeviceMotionUpdates()
    }
    
    // MARK: - Public Interface
    
    /// Validate plane measurements using motion data
    func validatePlane(_ plane: EnhancedPlane, using session: ARSession) async -> MotionValidationResult {
        print("🎯 Validating plane measurements using motion data")
        
        let validationId = UUID()
        let validationSession = ValidationSession(
            id: validationId,
            plane: plane,
            startTime: Date(),
            arSession: session
        )
        
        validationSessions[validationId] = validationSession
        
        // Perform validation
        let result = await performMotionValidation(validationSession)
        
        // Cleanup
        validationSessions.removeValue(forKey: validationId)
        
        print("✅ Motion validation completed with confidence: \(result.confidence)")
        return result
    }
    
    /// Get current device motion stability
    func getCurrentMotionStability() -> MotionStability {
        guard let latestMotion = motionData.last else {
            return MotionStability(isStable: false, motionMagnitude: 1.0, confidence: 0.0)
        }
        
        let motionMagnitude = calculateMotionMagnitude(latestMotion)
        let isStable = motionMagnitude < configuration.motionThreshold
        let confidence = calculateStabilityConfidence(motionMagnitude)
        
        return MotionStability(
            isStable: isStable,
            motionMagnitude: motionMagnitude,
            confidence: confidence
        )
    }
    
    /// Check if device is stable enough for accurate measurements
    func isDeviceStableForMeasurement() -> Bool {
        let stability = getCurrentMotionStability()
        return stability.isStable && stability.confidence > configuration.confidenceThreshold
    }
    
    // MARK: - Motion Tracking Setup
    
    private func setupMotionTracking() {
        guard motionManager.isDeviceMotionAvailable else {
            print("❌ Device motion not available")
            return
        }
        
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0 // 60 Hz
        
        motionManager.startDeviceMotionUpdates(using: .xMagneticNorthZVertical, to: .main) { [weak self] motion, error in
            if let error = error {
                print("❌ Motion tracking error: \(error)")
                return
            }
            
            if let motion = motion {
                self?.handleMotionUpdate(motion)
            }
        }
        
        print("📱 Motion tracking started")
    }
    
    private func handleMotionUpdate(_ motion: CMDeviceMotion) {
        motionData.append(motion)
        
        // Keep only recent motion data (last 10 seconds)
        let cutoffTime = Date().timeIntervalSince1970 - 10.0
        motionData.removeAll { $0.timestamp < cutoffTime }
    }
    
    // MARK: - Validation Implementation
    
    private func performMotionValidation(_ session: ValidationSession) async -> MotionValidationResult {
        var issues: [MotionValidationIssue] = []
        
        // Method 1: Device motion validation
        let deviceMotionResult = await validateWithDeviceMotion(session)
        if !deviceMotionResult.isValid {
            issues.append(contentsOf: deviceMotionResult.issues)
        }
        
        // Method 2: Visual-inertial validation
        let visualInertialResult = await validateWithVisualInertial(session)
        if !visualInertialResult.isValid {
            issues.append(contentsOf: visualInertialResult.issues)
        }
        
        // Method 3: Multi-frame consistency validation
        let multiFrameResult = await validateWithMultiFrame(session)
        if !multiFrameResult.isValid {
            issues.append(contentsOf: multiFrameResult.issues)
        }
        
        // Combine validation results
        let overallConfidence = (deviceMotionResult.confidence + visualInertialResult.confidence + multiFrameResult.confidence) / 3.0
        let motionConsistency = calculateMotionConsistency(session)
        let stabilityScore = calculateStabilityScore(session)
        
        let isValid = issues.filter { $0.severity == .critical }.isEmpty && overallConfidence > configuration.confidenceThreshold
        
        return MotionValidationResult(
            isValid: isValid,
            confidence: overallConfidence,
            motionConsistency: motionConsistency,
            stabilityScore: stabilityScore,
            validationMethod: .combined,
            issues: issues,
            timestamp: Date()
        )
    }
    
    private func validateWithDeviceMotion(_ session: ValidationSession) async -> ValidationSubResult {
        print("📱 Validating with device motion")
        
        var issues: [MotionValidationIssue] = []
        
        // Check motion stability during measurement
        let motionStability = analyzeMotionStability(session)
        
        if motionStability.excessiveMotion {
            issues.append(MotionValidationIssue(
                type: .excessiveMotion,
                severity: .major,
                description: "Excessive device motion detected during measurement"
            ))
        }
        
        if motionStability.inconsistentMotion {
            issues.append(MotionValidationIssue(
                type: .inconsistentTracking,
                severity: .minor,
                description: "Inconsistent motion patterns detected"
            ))
        }
        
        let confidence = calculateDeviceMotionConfidence(motionStability)
        
        return ValidationSubResult(
            isValid: issues.filter { $0.severity == .critical || $0.severity == .major }.isEmpty,
            confidence: confidence,
            issues: issues
        )
    }
    
    private func validateWithVisualInertial(_ session: ValidationSession) async -> ValidationSubResult {
        print("👁 Validating with visual-inertial tracking")
        
        var issues: [MotionValidationIssue] = []
        
        // Analyze ARKit tracking quality
        let trackingQuality = analyzeARKitTrackingQuality(session)
        
        if trackingQuality.hasTrackingLoss {
            issues.append(MotionValidationIssue(
                type: .inconsistentTracking,
                severity: .major,
                description: "ARKit tracking loss detected during measurement"
            ))
        }
        
        if trackingQuality.hasCalibrationDrift {
            issues.append(MotionValidationIssue(
                type: .calibrationDrift,
                severity: .minor,
                description: "Calibration drift detected in visual-inertial tracking"
            ))
        }
        
        let confidence = trackingQuality.overallConfidence
        
        return ValidationSubResult(
            isValid: issues.filter { $0.severity == .critical || $0.severity == .major }.isEmpty,
            confidence: confidence,
            issues: issues
        )
    }
    
    private func validateWithMultiFrame(_ session: ValidationSession) async -> ValidationSubResult {
        print("🎬 Validating with multi-frame analysis")
        
        var issues: [MotionValidationIssue] = []
        
        // Analyze plane consistency across multiple frames
        let frameConsistency = analyzeMultiFrameConsistency(session)
        
        if frameConsistency.lowStability {
            issues.append(MotionValidationIssue(
                type: .lowStability,
                severity: .minor,
                description: "Low stability detected across multiple frames"
            ))
        }
        
        let confidence = frameConsistency.consistencyScore
        
        return ValidationSubResult(
            isValid: issues.filter { $0.severity == .critical || $0.severity == .major }.isEmpty,
            confidence: confidence,
            issues: issues
        )
    }
    
    // MARK: - Analysis Methods
    
    private func analyzeMotionStability(_ session: ValidationSession) -> MotionStabilityAnalysis {
        let recentMotion = getRecentMotionData(since: session.startTime)
        
        var excessiveMotion = false
        var inconsistentMotion = false
        var totalMotion: Float = 0.0
        
        for motion in recentMotion {
            let motionMagnitude = calculateMotionMagnitude(motion)
            totalMotion += motionMagnitude
            
            if motionMagnitude > configuration.motionThreshold {
                excessiveMotion = true
            }
        }
        
        let averageMotion = recentMotion.isEmpty ? 0.0 : totalMotion / Float(recentMotion.count)
        
        // Check for motion consistency
        let motionVariance = calculateMotionVariance(recentMotion)
        inconsistentMotion = motionVariance > 0.05 // 5cm variance threshold
        
        return MotionStabilityAnalysis(
            excessiveMotion: excessiveMotion,
            inconsistentMotion: inconsistentMotion,
            averageMotion: averageMotion,
            motionVariance: motionVariance
        )
    }
    
    private func analyzeARKitTrackingQuality(_ session: ValidationSession) -> TrackingQualityAnalysis {
        // Analyze ARKit tracking quality during the session
        // This would examine the ARSession's tracking state history
        
        return TrackingQualityAnalysis(
            hasTrackingLoss: false, // Placeholder
            hasCalibrationDrift: false, // Placeholder
            overallConfidence: 0.85 // Placeholder
        )
    }
    
    private func analyzeMultiFrameConsistency(_ session: ValidationSession) -> FrameConsistencyAnalysis {
        // Analyze plane consistency across multiple frames
        // This would track how the plane measurements change over time
        
        return FrameConsistencyAnalysis(
            lowStability: false, // Placeholder
            consistencyScore: 0.9 // Placeholder
        )
    }
    
    private func calculateMotionMagnitude(_ motion: CMDeviceMotion) -> Float {
        let acceleration = motion.userAcceleration
        let rotationRate = motion.rotationRate
        
        // Combine linear and angular motion
        let linearMagnitude = sqrt(Float(acceleration.x * acceleration.x + acceleration.y * acceleration.y + acceleration.z * acceleration.z))
        let angularMagnitude = sqrt(Float(rotationRate.x * rotationRate.x + rotationRate.y * rotationRate.y + rotationRate.z * rotationRate.z))
        
        return linearMagnitude + angularMagnitude * 0.1 // Weight angular motion less
    }
    
    private func calculateMotionVariance(_ motionData: [CMDeviceMotion]) -> Float {
        guard motionData.count > 1 else { return 0.0 }
        
        let motionMagnitudes = motionData.map { calculateMotionMagnitude($0) }
        let average = motionMagnitudes.reduce(0, +) / Float(motionMagnitudes.count)
        
        let variance = motionMagnitudes.map { pow($0 - average, 2) }.reduce(0, +) / Float(motionMagnitudes.count)
        
        return sqrt(variance)
    }
    
    private func calculateStabilityConfidence(_ motionMagnitude: Float) -> Float {
        // Calculate confidence based on motion magnitude
        let normalizedMotion = min(motionMagnitude / configuration.motionThreshold, 1.0)
        return max(0.0, 1.0 - normalizedMotion)
    }
    
    private func calculateMotionConsistency(_ session: ValidationSession) -> Float {
        let recentMotion = getRecentMotionData(since: session.startTime)
        guard !recentMotion.isEmpty else { return 0.0 }
        
        let motionVariance = calculateMotionVariance(recentMotion)
        return max(0.0, 1.0 - motionVariance * 10.0) // Normalize variance to 0-1 scale
    }
    
    private func calculateStabilityScore(_ session: ValidationSession) -> Float {
        let stability = getCurrentMotionStability()
        return stability.confidence
    }
    
    private func calculateDeviceMotionConfidence(_ analysis: MotionStabilityAnalysis) -> Float {
        var confidence: Float = 1.0
        
        if analysis.excessiveMotion {
            confidence -= 0.3
        }
        
        if analysis.inconsistentMotion {
            confidence -= 0.2
        }
        
        // Adjust based on average motion
        confidence -= analysis.averageMotion * 2.0
        
        return max(0.0, confidence)
    }
    
    private func getRecentMotionData(since startTime: Date) -> [CMDeviceMotion] {
        let startTimestamp = startTime.timeIntervalSince1970
        return motionData.filter { $0.timestamp >= startTimestamp }
    }
}

// MARK: - Supporting Data Structures

struct ValidationSession {
    let id: UUID
    let plane: EnhancedPlane
    let startTime: Date
    let arSession: ARSession
}

struct ValidationSubResult {
    let isValid: Bool
    let confidence: Float
    let issues: [MotionValidationIssue]
}

struct MotionStability {
    let isStable: Bool
    let motionMagnitude: Float
    let confidence: Float
}

struct MotionStabilityAnalysis {
    let excessiveMotion: Bool
    let inconsistentMotion: Bool
    let averageMotion: Float
    let motionVariance: Float
}

struct TrackingQualityAnalysis {
    let hasTrackingLoss: Bool
    let hasCalibrationDrift: Bool
    let overallConfidence: Float
}

struct FrameConsistencyAnalysis {
    let lowStability: Bool
    let consistencyScore: Float
}

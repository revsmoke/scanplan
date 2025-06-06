import Foundation
import ARKit
import CoreMotion
import simd
import Combine

/// Advanced Motion Compensation Engine for measurement validation
/// Implements sophisticated motion tracking and compensation algorithms for professional accuracy
@MainActor
class MotionCompensationEngine: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var motionState: MotionState = .unknown
    @Published var compensationMetrics: CompensationMetrics = CompensationMetrics()
    @Published var trackingQuality: TrackingQuality = .unknown
    @Published var isCompensating: Bool = false
    @Published var validationResults: [ValidationResult] = []
    
    // MARK: - Configuration
    
    struct CompensationConfiguration {
        let motionThreshold: Float = 0.05 // 5cm motion threshold
        let angularThreshold: Float = 0.1 // 0.1 radian angular threshold
        let stabilityDuration: TimeInterval = 1.0 // 1 second stability requirement
        let compensationAccuracy: Float = 0.001 // 1mm compensation accuracy
        let enablePredictiveCompensation: Bool = true
        let enableAdaptiveFiltering: Bool = true
        let maxCompensationHistory: Int = 100
        let validationFrequency: Double = 30.0 // 30 Hz validation
    }
    
    private let configuration = CompensationConfiguration()
    
    // MARK: - Motion Tracking Components
    
    private let motionManager = CMMotionManager()
    private let trackingValidator: TrackingValidator
    private let motionPredictor: MotionPredictor
    private let compensationFilter: CompensationFilter
    private let accuracyAssessor: AccuracyAssessor
    
    // MARK: - Motion History
    
    private var motionHistory: [MotionFrame] = []
    private var compensationHistory: [CompensationFrame] = []
    private var validationHistory: [ValidationResult] = []
    
    // MARK: - Performance Monitoring
    
    private var processingTimes: [TimeInterval] = []
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    override init() {
        self.trackingValidator = TrackingValidator()
        self.motionPredictor = MotionPredictor()
        self.compensationFilter = CompensationFilter()
        self.accuracyAssessor = AccuracyAssessor()
        
        super.init()
        
        setupMotionTracking()
        setupValidationTimer()
        setupPerformanceMonitoring()
    }
    
    deinit {
        stopMotionTracking()
    }
    
    // MARK: - Public Interface
    
    /// Start motion compensation and tracking validation
    func startMotionCompensation() {
        print("🎯 Starting motion compensation and tracking validation")
        
        guard motionManager.isDeviceMotionAvailable else {
            print("❌ Device motion not available")
            return
        }
        
        isCompensating = true
        
        // Start motion tracking
        startMotionTracking()
        
        // Initialize tracking validator
        trackingValidator.startValidation()
        
        // Initialize motion predictor
        motionPredictor.startPrediction()
        
        print("✅ Motion compensation started")
    }
    
    /// Stop motion compensation
    func stopMotionCompensation() {
        print("⏹ Stopping motion compensation")
        
        isCompensating = false
        
        // Stop motion tracking
        stopMotionTracking()
        
        // Stop validation
        trackingValidator.stopValidation()
        
        // Stop prediction
        motionPredictor.stopPrediction()
        
        print("✅ Motion compensation stopped")
    }
    
    /// Compensate measurement for device motion
    func compensateMeasurement(_ measurement: Measurement, at timestamp: TimeInterval) async -> CompensatedMeasurement {
        print("🔧 Compensating measurement for device motion")
        
        let startTime = Date()
        
        // Get motion data at measurement time
        let motionFrame = getMotionFrame(at: timestamp)
        
        // Apply motion compensation
        let compensatedValue = await applyMotionCompensation(measurement, motionFrame: motionFrame)
        
        // Validate compensation accuracy
        let validationResult = await validateCompensation(original: measurement, compensated: compensatedValue, motionFrame: motionFrame)
        
        // Create compensated measurement
        let compensatedMeasurement = CompensatedMeasurement(
            original: measurement,
            compensated: compensatedValue,
            motionFrame: motionFrame,
            validationResult: validationResult,
            timestamp: Date(),
            processingTime: Date().timeIntervalSince(startTime)
        )
        
        // Add to validation history
        addToValidationHistory(validationResult)
        
        // Update performance metrics
        updatePerformanceMetrics(processingTime: Date().timeIntervalSince(startTime))
        
        print("✅ Measurement compensation completed")
        return compensatedMeasurement
    }
    
    /// Validate tracking quality in real-time
    func validateTrackingQuality(_ arFrame: ARFrame) async -> TrackingValidationResult {
        return await trackingValidator.validateTracking(arFrame, motionHistory: motionHistory)
    }
    
    /// Predict future motion for proactive compensation
    func predictMotion(timeAhead: TimeInterval) async -> PredictedMotion? {
        guard configuration.enablePredictiveCompensation else { return nil }
        
        return await motionPredictor.predictMotion(timeAhead: timeAhead, history: motionHistory)
    }
    
    /// Get current motion stability assessment
    func getMotionStability() -> MotionStability {
        guard let latestMotion = motionHistory.last else {
            return MotionStability(isStable: false, confidence: 0.0, motionMagnitude: 1.0)
        }
        
        return assessMotionStability(latestMotion)
    }
    
    /// Clear motion and compensation history
    func clearHistory() {
        motionHistory.removeAll()
        compensationHistory.removeAll()
        validationHistory.removeAll()
        validationResults.removeAll()
    }
    
    // MARK: - Motion Tracking Setup
    
    private func setupMotionTracking() {
        guard motionManager.isDeviceMotionAvailable else {
            print("❌ Device motion not available")
            return
        }
        
        // Configure motion manager
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0 // 60 Hz
        motionManager.showsDeviceMovementDisplay = true
        
        print("🔧 Motion tracking configured")
    }
    
    private func startMotionTracking() {
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
    
    private func stopMotionTracking() {
        motionManager.stopDeviceMotionUpdates()
        print("📱 Motion tracking stopped")
    }
    
    private func handleMotionUpdate(_ motion: CMDeviceMotion) {
        let motionFrame = MotionFrame(
            timestamp: motion.timestamp,
            attitude: motion.attitude,
            rotationRate: motion.rotationRate,
            userAcceleration: motion.userAcceleration,
            gravity: motion.gravity,
            magneticField: motion.magneticField
        )
        
        addToMotionHistory(motionFrame)
        updateMotionState(motionFrame)
    }
    
    private func addToMotionHistory(_ motionFrame: MotionFrame) {
        motionHistory.append(motionFrame)
        
        // Keep only recent history
        if motionHistory.count > configuration.maxCompensationHistory {
            motionHistory.removeFirst()
        }
    }
    
    private func updateMotionState(_ motionFrame: MotionFrame) {
        let stability = assessMotionStability(motionFrame)
        
        if stability.isStable {
            motionState = .stable
        } else if stability.motionMagnitude > configuration.motionThreshold * 2 {
            motionState = .highMotion
        } else {
            motionState = .lowMotion
        }
        
        trackingQuality = determineTrackingQuality(stability)
    }
    
    // MARK: - Motion Compensation Algorithms
    
    private func applyMotionCompensation(_ measurement: Measurement, motionFrame: MotionFrame) async -> CompensatedValue {
        print("🔄 Applying motion compensation algorithms")
        
        // Method 1: Linear motion compensation
        let linearCompensation = await applyLinearCompensation(measurement, motionFrame: motionFrame)
        
        // Method 2: Angular motion compensation
        let angularCompensation = await applyAngularCompensation(linearCompensation, motionFrame: motionFrame)
        
        // Method 3: Predictive compensation
        var predictiveCompensation = angularCompensation
        if configuration.enablePredictiveCompensation {
            predictiveCompensation = await applyPredictiveCompensation(angularCompensation, motionFrame: motionFrame)
        }
        
        // Method 4: Adaptive filtering
        var finalCompensation = predictiveCompensation
        if configuration.enableAdaptiveFiltering {
            finalCompensation = await compensationFilter.applyAdaptiveFiltering(predictiveCompensation, motionFrame: motionFrame)
        }
        
        return finalCompensation
    }
    
    private func applyLinearCompensation(_ measurement: Measurement, motionFrame: MotionFrame) async -> CompensatedValue {
        // Compensate for linear motion (translation)
        let acceleration = motionFrame.userAcceleration
        let gravity = motionFrame.gravity
        
        // Calculate motion-induced measurement error
        let motionError = calculateLinearMotionError(acceleration: acceleration, gravity: gravity, measurement: measurement)
        
        // Apply compensation
        let compensatedValue = measurement.value - motionError
        
        return CompensatedValue(
            value: compensatedValue,
            compensationType: .linear,
            confidence: calculateCompensationConfidence(motionError: motionError)
        )
    }
    
    private func applyAngularCompensation(_ compensatedValue: CompensatedValue, motionFrame: MotionFrame) async -> CompensatedValue {
        // Compensate for angular motion (rotation)
        let rotationRate = motionFrame.rotationRate
        let attitude = motionFrame.attitude
        
        // Calculate rotation-induced measurement error
        let rotationError = calculateAngularMotionError(rotationRate: rotationRate, attitude: attitude, value: compensatedValue.value)
        
        // Apply compensation
        let finalValue = compensatedValue.value - rotationError
        
        return CompensatedValue(
            value: finalValue,
            compensationType: .angular,
            confidence: min(compensatedValue.confidence, calculateAngularCompensationConfidence(rotationError: rotationError))
        )
    }
    
    private func applyPredictiveCompensation(_ compensatedValue: CompensatedValue, motionFrame: MotionFrame) async -> CompensatedValue {
        // Apply predictive compensation based on motion trends
        guard let predictedMotion = await motionPredictor.predictMotion(timeAhead: 0.1, history: motionHistory) else {
            return compensatedValue
        }
        
        // Calculate predictive correction
        let predictiveCorrection = calculatePredictiveCorrection(predictedMotion: predictedMotion, currentValue: compensatedValue.value)
        
        // Apply correction
        let finalValue = compensatedValue.value + predictiveCorrection
        
        return CompensatedValue(
            value: finalValue,
            compensationType: .predictive,
            confidence: min(compensatedValue.confidence, predictedMotion.confidence)
        )
    }
    
    // MARK: - Motion Error Calculations
    
    private func calculateLinearMotionError(acceleration: CMAcceleration, gravity: CMAcceleration, measurement: Measurement) -> Float {
        // Calculate measurement error due to linear motion
        let netAcceleration = simd_float3(
            Float(acceleration.x - gravity.x),
            Float(acceleration.y - gravity.y),
            Float(acceleration.z - gravity.z)
        )
        
        let accelerationMagnitude = simd_length(netAcceleration)
        
        // Motion error is proportional to acceleration and measurement distance
        let motionError = accelerationMagnitude * measurement.distance * 0.001 // Empirical factor
        
        return motionError
    }
    
    private func calculateAngularMotionError(rotationRate: CMRotationRate, attitude: CMAttitude, value: Float) -> Float {
        // Calculate measurement error due to angular motion
        let angularVelocity = simd_float3(
            Float(rotationRate.x),
            Float(rotationRate.y),
            Float(rotationRate.z)
        )
        
        let angularMagnitude = simd_length(angularVelocity)
        
        // Angular error affects measurements based on distance from rotation center
        let angularError = angularMagnitude * value * 0.01 // Empirical factor
        
        return angularError
    }
    
    private func calculatePredictiveCorrection(predictedMotion: PredictedMotion, currentValue: Float) -> Float {
        // Calculate correction based on predicted motion
        let motionMagnitude = simd_length(predictedMotion.predictedVelocity)
        let correctionFactor = motionMagnitude * 0.005 // Empirical factor
        
        return correctionFactor * currentValue
    }
    
    // MARK: - Validation and Assessment
    
    private func validateCompensation(original: Measurement, compensated: CompensatedValue, motionFrame: MotionFrame) async -> ValidationResult {
        print("✅ Validating compensation accuracy")
        
        // Calculate compensation effectiveness
        let effectiveness = await accuracyAssessor.assessCompensationEffectiveness(
            original: original,
            compensated: compensated,
            motionFrame: motionFrame
        )
        
        // Assess measurement accuracy
        let accuracy = await accuracyAssessor.assessMeasurementAccuracy(
            compensated: compensated,
            motionFrame: motionFrame
        )
        
        // Determine validation status
        let isValid = effectiveness > 0.8 && accuracy.meetsRequirements
        
        return ValidationResult(
            isValid: isValid,
            effectiveness: effectiveness,
            accuracy: accuracy,
            confidence: min(effectiveness, accuracy.confidence),
            timestamp: Date()
        )
    }
    
    private func addToValidationHistory(_ result: ValidationResult) {
        validationHistory.append(result)
        validationResults.append(result)
        
        // Keep only recent history
        if validationHistory.count > 100 {
            validationHistory.removeFirst()
        }
        
        if validationResults.count > 50 {
            validationResults.removeFirst()
        }
    }
    
    // MARK: - Motion Analysis
    
    private func getMotionFrame(at timestamp: TimeInterval) -> MotionFrame {
        // Find motion frame closest to timestamp
        guard !motionHistory.isEmpty else {
            return MotionFrame.default()
        }
        
        let closestFrame = motionHistory.min { frame1, frame2 in
            abs(frame1.timestamp - timestamp) < abs(frame2.timestamp - timestamp)
        }
        
        return closestFrame ?? motionHistory.last!
    }
    
    private func assessMotionStability(_ motionFrame: MotionFrame) -> MotionStability {
        // Assess motion stability based on acceleration and rotation
        let acceleration = motionFrame.userAcceleration
        let rotationRate = motionFrame.rotationRate
        
        let accelerationMagnitude = sqrt(acceleration.x * acceleration.x + acceleration.y * acceleration.y + acceleration.z * acceleration.z)
        let rotationMagnitude = sqrt(rotationRate.x * rotationRate.x + rotationRate.y * rotationRate.y + rotationRate.z * rotationRate.z)
        
        let motionMagnitude = Float(accelerationMagnitude + rotationMagnitude * 0.1)
        let isStable = motionMagnitude < configuration.motionThreshold
        let confidence = max(0.0, 1.0 - motionMagnitude / configuration.motionThreshold)
        
        return MotionStability(
            isStable: isStable,
            confidence: confidence,
            motionMagnitude: motionMagnitude
        )
    }
    
    private func determineTrackingQuality(_ stability: MotionStability) -> TrackingQuality {
        if stability.confidence > 0.9 {
            return .excellent
        } else if stability.confidence > 0.7 {
            return .good
        } else if stability.confidence > 0.5 {
            return .acceptable
        } else {
            return .poor
        }
    }
    
    // MARK: - Confidence Calculations
    
    private func calculateCompensationConfidence(motionError: Float) -> Float {
        // Calculate confidence based on motion error magnitude
        let normalizedError = motionError / configuration.compensationAccuracy
        return max(0.0, 1.0 - normalizedError)
    }
    
    private func calculateAngularCompensationConfidence(rotationError: Float) -> Float {
        // Calculate confidence for angular compensation
        let normalizedError = rotationError / (configuration.compensationAccuracy * 10) // Angular errors are typically larger
        return max(0.0, 1.0 - normalizedError)
    }
    
    // MARK: - Performance Monitoring
    
    private func setupValidationTimer() {
        Timer.publish(every: 1.0 / configuration.validationFrequency, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.performPeriodicValidation()
            }
            .store(in: &cancellables)
    }
    
    private func performPeriodicValidation() {
        // Perform periodic validation of motion compensation system
        guard isCompensating else { return }
        
        // Update compensation metrics
        updateCompensationMetrics()
    }
    
    private func updateCompensationMetrics() {
        guard !validationHistory.isEmpty else { return }
        
        let recentResults = validationHistory.suffix(30) // Last 30 validations
        let averageEffectiveness = recentResults.reduce(0) { $0 + $1.effectiveness } / Float(recentResults.count)
        let averageConfidence = recentResults.reduce(0) { $0 + $1.confidence } / Float(recentResults.count)
        let validationSuccessRate = Float(recentResults.filter { $0.isValid }.count) / Float(recentResults.count)
        
        compensationMetrics = CompensationMetrics(
            averageEffectiveness: averageEffectiveness,
            averageConfidence: averageConfidence,
            validationSuccessRate: validationSuccessRate,
            totalValidations: validationHistory.count,
            averageProcessingTime: processingTimes.isEmpty ? 0 : processingTimes.reduce(0, +) / Double(processingTimes.count)
        )
    }
    
    private func setupPerformanceMonitoring() {
        // Monitor performance metrics
        Timer.publish(every: 5.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updatePerformanceMetrics()
            }
            .store(in: &cancellables)
    }
    
    private func updatePerformanceMetrics(processingTime: TimeInterval? = nil) {
        if let processingTime = processingTime {
            processingTimes.append(processingTime)
            
            // Keep only recent processing times
            if processingTimes.count > 100 {
                processingTimes.removeFirst()
            }
        }
    }
    
    private func updatePerformanceMetrics() {
        // Update overall performance metrics
        updateCompensationMetrics()
    }
}

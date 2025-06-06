import Foundation
import Vision
import CoreGraphics
import simd

// MARK: - Vision Analysis Results

/// Comprehensive vision analysis result
struct VisionAnalysisResult: Identifiable, Codable {
    let id = UUID()
    let objectDetection: ObjectDetectionResult
    let textRecognition: TextRecognitionResult
    let barcodeDetection: BarcodeDetectionResult
    let imageClassification: ImageClassificationResult
    let featureTracking: FeatureTrackingResult
    let timestamp: Date
    let processingTime: TimeInterval
    let frameQuality: FrameQuality
    
    var overallConfidence: Float {
        return (objectDetection.confidence + 
                textRecognition.confidence + 
                barcodeDetection.confidence + 
                imageClassification.confidence + 
                featureTracking.confidence) / 5.0
    }
    
    var hasHighQualityResults: Bool {
        return overallConfidence > 0.8 && frameQuality != .poor
    }
}

/// Object detection result
struct ObjectDetectionResult: Codable {
    let objects: [DetectedObject]
    let confidence: Float
    
    var objectCount: Int {
        return objects.count
    }
    
    var highConfidenceObjects: [DetectedObject] {
        return objects.filter { $0.confidence > 0.8 }
    }
}

/// Text recognition result
struct TextRecognitionResult: Codable {
    let textRegions: [RecognizedText]
    let confidence: Float
    
    var recognizedStrings: [String] {
        return textRegions.map { $0.text }
    }
    
    var totalTextLength: Int {
        return recognizedStrings.joined().count
    }
}

/// Barcode detection result
struct BarcodeDetectionResult: Codable {
    let barcodes: [DetectedBarcode]
    let confidence: Float
    
    var barcodeCount: Int {
        return barcodes.count
    }
    
    var qrCodes: [DetectedBarcode] {
        return barcodes.filter { $0.symbology == .QR }
    }
}

/// Image classification result
struct ImageClassificationResult: Codable {
    let classifications: [ImageClassification]
    let confidence: Float
    
    var topClassification: ImageClassification? {
        return classifications.first
    }
    
    var classificationCount: Int {
        return classifications.count
    }
}

/// Feature tracking result
struct FeatureTrackingResult: Codable {
    let features: [TrackedFeature]
    let confidence: Float
    
    var featureCount: Int {
        return features.count
    }
    
    var stableFeatures: [TrackedFeature] {
        return features.filter { $0.stability > 0.8 }
    }
}

// MARK: - Detected Objects

/// Detected object in image
struct DetectedObject: Identifiable, Codable {
    let id: UUID
    let boundingBox: CGRect
    let confidence: Float
    let objectType: ObjectType
    let timestamp: Date
    
    var center: CGPoint {
        return CGPoint(x: boundingBox.midX, y: boundingBox.midY)
    }
    
    var area: CGFloat {
        return boundingBox.width * boundingBox.height
    }
    
    var aspectRatio: CGFloat {
        return boundingBox.width / boundingBox.height
    }
}

enum ObjectType: String, CaseIterable, Codable {
    case rectangle = "rectangle"
    case circle = "circle"
    case text = "text"
    case barcode = "barcode"
    case face = "face"
    case unknown = "unknown"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var icon: String {
        switch self {
        case .rectangle: return "rectangle"
        case .circle: return "circle"
        case .text: return "text.alignleft"
        case .barcode: return "barcode"
        case .face: return "face.smiling"
        case .unknown: return "questionmark"
        }
    }
}

// MARK: - Text Recognition

/// Recognized text region
struct RecognizedText: Identifiable, Codable {
    let id = UUID()
    let text: String
    let boundingBox: CGRect
    let confidence: Float
    let language: String?
    
    var wordCount: Int {
        return text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
    }
    
    var isNumeric: Bool {
        return text.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
    }
    
    var containsEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return text.range(of: emailRegex, options: .regularExpression) != nil
    }
    
    var containsURL: Bool {
        let urlRegex = "https?://[\\w\\-_]+(\\.[\\w\\-_]+)+([\\w\\-\\.,@?^=%&:/~\\+#]*[\\w\\-\\@?^=%&/~\\+#])?"
        return text.range(of: urlRegex, options: .regularExpression) != nil
    }
}

// MARK: - Barcode Detection

/// Detected barcode
struct DetectedBarcode: Identifiable, Codable {
    let id = UUID()
    let payload: String
    let symbology: BarcodeSymbology
    let boundingBox: CGRect
    let confidence: Float
    
    var isQRCode: Bool {
        return symbology == .QR
    }
    
    var isProductCode: Bool {
        return symbology == .ean8 || symbology == .ean13 || symbology == .code128
    }
}

enum BarcodeSymbology: String, CaseIterable, Codable {
    case QR = "QR"
    case code128 = "code128"
    case code39 = "code39"
    case code93 = "code93"
    case ean8 = "ean8"
    case ean13 = "ean13"
    case pdf417 = "pdf417"
    case dataMatrix = "dataMatrix"
    
    var displayName: String {
        switch self {
        case .QR: return "QR Code"
        case .code128: return "Code 128"
        case .code39: return "Code 39"
        case .code93: return "Code 93"
        case .ean8: return "EAN-8"
        case .ean13: return "EAN-13"
        case .pdf417: return "PDF417"
        case .dataMatrix: return "Data Matrix"
        }
    }
}

// MARK: - Image Classification

/// Image classification result
struct ImageClassification: Identifiable, Codable {
    let id = UUID()
    let identifier: String
    let confidence: Float
    let category: ClassificationCategory
    
    var displayName: String {
        return identifier.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

enum ClassificationCategory: String, CaseIterable, Codable {
    case object = "object"
    case scene = "scene"
    case activity = "activity"
    case concept = "concept"
    case unknown = "unknown"
    
    var displayName: String {
        return rawValue.capitalized
    }
}

// MARK: - Feature Tracking

/// Tracked visual feature
struct TrackedFeature: Identifiable, Codable {
    let id: UUID
    let position: CGPoint
    let featureType: FeatureType
    let stability: Float
    let trackingHistory: [CGPoint]
    
    var isStable: Bool {
        return stability > 0.8
    }
    
    var movementDistance: Float {
        guard trackingHistory.count > 1 else { return 0.0 }
        
        var totalDistance: Float = 0.0
        for i in 1..<trackingHistory.count {
            let prev = trackingHistory[i-1]
            let curr = trackingHistory[i]
            let distance = sqrt(pow(curr.x - prev.x, 2) + pow(curr.y - prev.y, 2))
            totalDistance += Float(distance)
        }
        
        return totalDistance
    }
}

enum FeatureType: String, CaseIterable, Codable {
    case corner = "corner"
    case edge = "edge"
    case blob = "blob"
    case keypoint = "keypoint"
    case unknown = "unknown"
    
    var displayName: String {
        return rawValue.capitalized
    }
}

// MARK: - Object Analysis

/// Comprehensive object analysis
struct ObjectAnalysis: Identifiable, Codable {
    let id = UUID()
    let object: DetectedObject
    let properties: ObjectProperties
    let spatialRelations: [SpatialRelation]
    let temporalConsistency: TemporalConsistency
    let analysisTimestamp: Date
    
    var analysisQuality: AnalysisQuality {
        let confidenceScore = object.confidence
        let consistencyScore = temporalConsistency.averageConfidence
        let overallScore = (confidenceScore + consistencyScore) / 2.0
        
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

/// Object properties
struct ObjectProperties: Codable {
    let size: simd_float3
    let distance: Float
    let material: MaterialType
    let shape: ObjectShape
    let color: simd_float3
    
    var volume: Float {
        return size.x * size.y * size.z
    }
    
    var surfaceArea: Float {
        return 2.0 * (size.x * size.y + size.y * size.z + size.z * size.x)
    }
}

enum ObjectShape: String, CaseIterable, Codable {
    case square = "square"
    case rectangular = "rectangular"
    case circular = "circular"
    case triangular = "triangular"
    case irregular = "irregular"
    case unknown = "unknown"
    
    var displayName: String {
        return rawValue.capitalized
    }
}

/// Spatial relationship between objects
struct SpatialRelation: Identifiable, Codable {
    let id = UUID()
    let targetObjectId: UUID
    let relationType: SpatialRelationType
    let distance: Float
    let direction: Direction
    
    var relationDescription: String {
        return "\(relationType.displayName) (\(direction.displayName), \(String(format: "%.2f", distance))m)"
    }
}

enum SpatialRelationType: String, CaseIterable, Codable {
    case adjacent = "adjacent"
    case overlapping = "overlapping"
    case contained = "contained"
    case containing = "containing"
    case distant = "distant"
    case aligned = "aligned"
    
    var displayName: String {
        return rawValue.capitalized
    }
}

enum Direction: String, CaseIterable, Codable {
    case above = "above"
    case below = "below"
    case left = "left"
    case right = "right"
    case front = "front"
    case back = "back"
    case unknown = "unknown"
    
    var displayName: String {
        return rawValue.capitalized
    }
}

/// Temporal consistency analysis
struct TemporalConsistency: Codable {
    let appearanceCount: Int
    let averageConfidence: Float
    let positionStability: Float
    let sizeStability: Float
    
    var overallStability: Float {
        return (averageConfidence + positionStability + sizeStability) / 3.0
    }
    
    var isConsistent: Bool {
        return overallStability > 0.8 && appearanceCount > 5
    }
}

// MARK: - Quality and Performance

/// Frame quality assessment
enum FrameQuality: String, CaseIterable, Codable {
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

/// Analysis quality levels
enum AnalysisQuality: String, CaseIterable, Codable {
    case excellent = "excellent"
    case good = "good"
    case acceptable = "acceptable"
    case poor = "poor"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var confidenceRange: ClosedRange<Float> {
        switch self {
        case .excellent: return 0.9...1.0
        case .good: return 0.8...0.9
        case .acceptable: return 0.7...0.8
        case .poor: return 0.0...0.7
        }
    }
}

/// Vision processing load
enum VisionProcessingLoad: String, CaseIterable {
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

/// Vision performance metrics
struct VisionMetrics: Codable {
    let averageProcessingTime: TimeInterval
    let averageConfidence: Float
    let totalRecognitions: Int
    let processingFrequency: Double
    let activeObjects: Int
    
    init() {
        self.averageProcessingTime = 0.0
        self.averageConfidence = 0.0
        self.totalRecognitions = 0
        self.processingFrequency = 0.0
        self.activeObjects = 0
    }
    
    init(averageProcessingTime: TimeInterval, averageConfidence: Float, totalRecognitions: Int,
         processingFrequency: Double, activeObjects: Int) {
        self.averageProcessingTime = averageProcessingTime
        self.averageConfidence = averageConfidence
        self.totalRecognitions = totalRecognitions
        self.processingFrequency = processingFrequency
        self.activeObjects = activeObjects
    }
    
    var performanceLevel: PerformanceLevel {
        if averageProcessingTime < 0.1 && averageConfidence > 0.9 {
            return .excellent
        } else if averageProcessingTime < 0.2 && averageConfidence > 0.8 {
            return .good
        } else if averageProcessingTime < 0.5 && averageConfidence > 0.7 {
            return .acceptable
        } else {
            return .poor
        }
    }
}

/// Vision performance metric
struct VisionPerformanceMetric: Codable {
    let metricType: VisionMetricType
    let value: Float
    let timestamp: Date
}

enum VisionMetricType: String, CaseIterable, Codable {
    case processingTime = "processing_time"
    case confidence = "confidence"
    case objectCount = "object_count"
    case frameQuality = "frame_quality"
    
    var displayName: String {
        switch self {
        case .processingTime: return "Processing Time"
        case .confidence: return "Confidence"
        case .objectCount: return "Object Count"
        case .frameQuality: return "Frame Quality"
        }
    }
    
    var unit: String {
        switch self {
        case .processingTime: return "ms"
        case .confidence: return "%"
        case .objectCount: return "objects"
        case .frameQuality: return "quality"
        }
    }
}

// MARK: - Recognition Results

/// Object recognition result
struct ObjectRecognitionResult: Identifiable, Codable {
    let id = UUID()
    let analysisResult: VisionAnalysisResult
    let timestamp: Date
    
    var hasObjects: Bool {
        return !analysisResult.objectDetection.objects.isEmpty
    }
    
    var hasText: Bool {
        return !analysisResult.textRecognition.textRegions.isEmpty
    }
    
    var hasBarcodes: Bool {
        return !analysisResult.barcodeDetection.barcodes.isEmpty
    }
}

/// Recognition frame for history tracking
struct RecognitionFrame: Codable {
    let result: VisionAnalysisResult
    let detectedObjects: [DetectedObject]
    let timestamp: Date
    
    var objectCount: Int {
        return detectedObjects.count
    }
    
    var averageConfidence: Float {
        guard !detectedObjects.isEmpty else { return 0.0 }
        return detectedObjects.reduce(0) { $0 + $1.confidence } / Float(detectedObjects.count)
    }
}

// MARK: - Supporting Classes (Placeholder)

class ObjectDetector {
    func initialize() async {
        print("🎯 Object detector initialized")
    }
    
    func detectObjects(in image: CVPixelBuffer, region: CGRect? = nil) async -> [DetectedObject] {
        // Placeholder implementation
        return [
            DetectedObject(
                id: UUID(),
                boundingBox: CGRect(x: 0.2, y: 0.3, width: 0.4, height: 0.3),
                confidence: 0.85,
                objectType: .rectangle,
                timestamp: Date()
            )
        ]
    }
    
    func detectObjects(image: CVPixelBuffer, requests: [VNRequest]) async -> ObjectDetectionResult {
        let objects = await detectObjects(in: image)
        return ObjectDetectionResult(objects: objects, confidence: 0.85)
    }
}

class TextRecognizer {
    func initialize() async {
        print("📝 Text recognizer initialized")
    }
    
    func recognizeText(in image: CVPixelBuffer, region: CGRect? = nil) async -> [RecognizedText] {
        // Placeholder implementation
        return [
            RecognizedText(
                text: "Sample Text",
                boundingBox: CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.1),
                confidence: 0.9,
                language: "en"
            )
        ]
    }
    
    func recognizeText(image: CVPixelBuffer, requests: [VNRequest]) async -> TextRecognitionResult {
        let textRegions = await recognizeText(in: image)
        return TextRecognitionResult(textRegions: textRegions, confidence: 0.9)
    }
}

class BarcodeDetector {
    func initialize() async {
        print("📱 Barcode detector initialized")
    }
    
    func detectBarcodes(in image: CVPixelBuffer) async -> [DetectedBarcode] {
        // Placeholder implementation
        return [
            DetectedBarcode(
                id: UUID(),
                payload: "https://example.com",
                symbology: .QR,
                boundingBox: CGRect(x: 0.3, y: 0.4, width: 0.2, height: 0.2),
                confidence: 0.95
            )
        ]
    }
    
    func detectBarcodes(image: CVPixelBuffer, requests: [VNRequest]) async -> BarcodeDetectionResult {
        let barcodes = await detectBarcodes(in: image)
        return BarcodeDetectionResult(barcodes: barcodes, confidence: 0.95)
    }
}

class ImageClassifier {
    func initialize() async {
        print("🏷 Image classifier initialized")
    }
    
    func classifyImage(_ image: CVPixelBuffer) async -> [ImageClassificationResult] {
        // Placeholder implementation
        return [
            ImageClassificationResult(
                classifications: [
                    ImageClassification(
                        identifier: "furniture",
                        confidence: 0.88,
                        category: .object
                    )
                ],
                confidence: 0.88
            )
        ]
    }
    
    func classifyImage(image: CVPixelBuffer, requests: [VNRequest]) async -> ImageClassificationResult {
        let results = await classifyImage(image)
        return results.first ?? ImageClassificationResult(classifications: [], confidence: 0.0)
    }
}

class FeatureTracker {
    func initialize() async {
        print("🎯 Feature tracker initialized")
    }
    
    func trackFeatures(in image: CVPixelBuffer, previousFeatures: [TrackedFeature]?) async -> [TrackedFeature] {
        // Placeholder implementation
        return [
            TrackedFeature(
                id: UUID(),
                position: CGPoint(x: 0.5, y: 0.5),
                featureType: .corner,
                stability: 0.9,
                trackingHistory: [CGPoint(x: 0.5, y: 0.5)]
            )
        ]
    }
    
    func trackFeatures(image: CVPixelBuffer, requests: [VNRequest]) async -> FeatureTrackingResult {
        let features = await trackFeatures(in: image, previousFeatures: nil)
        return FeatureTrackingResult(features: features, confidence: 0.9)
    }
}

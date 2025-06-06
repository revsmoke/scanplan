import Foundation
import CoreML
import ARKit
import simd
import CoreGraphics

// MARK: - Material Classification Results

/// Comprehensive material classification result
struct MaterialClassificationResult: Identifiable, Codable {
    let id = UUID()
    let materialType: MaterialType
    let confidence: Float // 0.0 - 1.0
    let textureProperties: TextureAnalysisResult
    let surfaceProperties: SurfacePropertyResult
    let features: ClassificationFeatures
    let region: CGRect
    let timestamp: Date
    let processingTime: TimeInterval
    
    var isHighConfidence: Bool {
        return confidence > 0.8
    }
    
    var qualityLevel: ClassificationQuality {
        if confidence > 0.9 {
            return .excellent
        } else if confidence > 0.8 {
            return .good
        } else if confidence > 0.7 {
            return .acceptable
        } else {
            return .poor
        }
    }
}

/// Material types for classification
enum MaterialType: String, CaseIterable, Codable {
    case wood = "wood"
    case metal = "metal"
    case plastic = "plastic"
    case glass = "glass"
    case concrete = "concrete"
    case ceramic = "ceramic"
    case fabric = "fabric"
    case leather = "leather"
    case stone = "stone"
    case paper = "paper"
    case rubber = "rubber"
    case composite = "composite"
    case unknown = "unknown"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var category: MaterialCategory {
        switch self {
        case .wood, .paper: return .organic
        case .metal, .glass, .ceramic, .stone: return .inorganic
        case .plastic, .rubber, .composite: return .synthetic
        case .fabric, .leather: return .textile
        case .concrete: return .construction
        case .unknown: return .unknown
        }
    }
    
    var typicalProperties: MaterialProperties {
        switch self {
        case .wood:
            return MaterialProperties(hardness: .medium, reflectivity: 0.3, porosity: 0.4, density: 0.6)
        case .metal:
            return MaterialProperties(hardness: .hard, reflectivity: 0.8, porosity: 0.0, density: 0.9)
        case .plastic:
            return MaterialProperties(hardness: .medium, reflectivity: 0.4, porosity: 0.1, density: 0.3)
        case .glass:
            return MaterialProperties(hardness: .hard, reflectivity: 0.9, porosity: 0.0, density: 0.7)
        case .concrete:
            return MaterialProperties(hardness: .hard, reflectivity: 0.2, porosity: 0.3, density: 0.8)
        case .ceramic:
            return MaterialProperties(hardness: .hard, reflectivity: 0.5, porosity: 0.1, density: 0.7)
        case .fabric:
            return MaterialProperties(hardness: .soft, reflectivity: 0.2, porosity: 0.8, density: 0.2)
        case .leather:
            return MaterialProperties(hardness: .medium, reflectivity: 0.3, porosity: 0.5, density: 0.4)
        case .stone:
            return MaterialProperties(hardness: .hard, reflectivity: 0.3, porosity: 0.2, density: 0.9)
        case .paper:
            return MaterialProperties(hardness: .soft, reflectivity: 0.7, porosity: 0.9, density: 0.1)
        case .rubber:
            return MaterialProperties(hardness: .soft, reflectivity: 0.1, porosity: 0.3, density: 0.4)
        case .composite:
            return MaterialProperties(hardness: .medium, reflectivity: 0.4, porosity: 0.2, density: 0.5)
        case .unknown:
            return MaterialProperties(hardness: .medium, reflectivity: 0.5, porosity: 0.5, density: 0.5)
        }
    }
}

enum MaterialCategory: String, CaseIterable, Codable {
    case organic = "organic"
    case inorganic = "inorganic"
    case synthetic = "synthetic"
    case textile = "textile"
    case construction = "construction"
    case unknown = "unknown"
    
    var displayName: String {
        return rawValue.capitalized
    }
}

/// Material properties structure
struct MaterialProperties: Codable {
    let hardness: HardnessLevel
    let reflectivity: Float // 0.0 - 1.0
    let porosity: Float // 0.0 - 1.0
    let density: Float // 0.0 - 1.0 (relative)
}

enum HardnessLevel: String, CaseIterable, Codable {
    case soft = "soft"
    case medium = "medium"
    case hard = "hard"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var mohsScale: ClosedRange<Float> {
        switch self {
        case .soft: return 1.0...3.0
        case .medium: return 3.0...6.0
        case .hard: return 6.0...10.0
        }
    }
}

// MARK: - Texture Analysis

/// Texture analysis result
struct TextureAnalysisResult: Codable {
    let textureType: TextureType
    let roughness: Float // 0.0 - 1.0
    let pattern: TexturePattern
    let confidence: Float // 0.0 - 1.0
    
    var textureDescription: String {
        return "\(textureType.displayName) with \(pattern.displayName) pattern"
    }
}

enum TextureType: String, CaseIterable, Codable {
    case smooth = "smooth"
    case rough = "rough"
    case textured = "textured"
    case polished = "polished"
    case matte = "matte"
    case glossy = "glossy"
    case brushed = "brushed"
    case woven = "woven"
    case unknown = "unknown"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var roughnessRange: ClosedRange<Float> {
        switch self {
        case .smooth, .polished, .glossy: return 0.0...0.2
        case .matte, .brushed: return 0.2...0.5
        case .textured, .woven: return 0.5...0.8
        case .rough: return 0.8...1.0
        case .unknown: return 0.0...1.0
        }
    }
}

enum TexturePattern: String, CaseIterable, Codable {
    case none = "none"
    case linear = "linear"
    case crosshatch = "crosshatch"
    case circular = "circular"
    case random = "random"
    case geometric = "geometric"
    case organic = "organic"
    case woven = "woven"
    case unknown = "unknown"
    
    var displayName: String {
        return rawValue.capitalized
    }
}

// MARK: - Surface Properties

/// Surface property analysis result
struct SurfacePropertyResult: Codable {
    let hardness: HardnessLevel
    let reflectivity: Float // 0.0 - 1.0
    let porosity: Float // 0.0 - 1.0
    let confidence: Float // 0.0 - 1.0
    
    var surfaceDescription: String {
        let reflectivityDesc = reflectivity > 0.7 ? "highly reflective" : reflectivity > 0.3 ? "moderately reflective" : "low reflectivity"
        let porosityDesc = porosity > 0.7 ? "highly porous" : porosity > 0.3 ? "moderately porous" : "low porosity"
        
        return "\(hardness.displayName), \(reflectivityDesc), \(porosityDesc)"
    }
}

// MARK: - Classification Features

/// Features extracted for classification
struct ClassificationFeatures: Codable {
    let imageFeatures: ImageFeatures
    let depthFeatures: DepthFeatures
    let textureFeatures: TextureFeatures
    let geometricFeatures: GeometricFeatures
    let surfaceNormals: [simd_float3]
    let extractionTimestamp: Date
    
    var featureCount: Int {
        return imageFeatures.featureVector.count + 
               depthFeatures.featureVector.count + 
               textureFeatures.featureVector.count + 
               geometricFeatures.featureVector.count
    }
}

/// Image-based features
struct ImageFeatures: Codable {
    let featureVector: [Float]
    let colorHistogram: [Float]
    let edgeFeatures: [Float]
    let textureDescriptors: [Float]
    let averageColor: simd_float3
    let brightness: Float
    let contrast: Float
    
    var dominantColor: simd_float3 {
        return averageColor
    }
}

/// Depth-based features
struct DepthFeatures: Codable {
    let featureVector: [Float]
    let depthVariance: Float
    let surfaceRoughness: Float
    let depthGradients: [Float]
    let averageDepth: Float
    let depthRange: Float
    
    var surfaceComplexity: Float {
        return depthVariance * surfaceRoughness
    }
}

/// Texture-specific features
struct TextureFeatures: Codable {
    let featureVector: [Float]
    let lbpHistogram: [Float] // Local Binary Pattern
    let glcmFeatures: [Float] // Gray-Level Co-occurrence Matrix
    let gaborResponses: [Float]
    let waveletFeatures: [Float]
    
    var textureComplexity: Float {
        return lbpHistogram.reduce(0, +) / Float(lbpHistogram.count)
    }
}

/// Geometric features
struct GeometricFeatures: Codable {
    let featureVector: [Float]
    let curvature: Float
    let planarity: Float
    let normalVariation: Float
    let edgeDensity: Float
    
    var geometricComplexity: Float {
        return curvature + normalVariation + edgeDensity
    }
}

// MARK: - Classification Results

/// Primary classification result
struct PrimaryClassificationResult: Codable {
    let materialType: MaterialType
    let confidence: Float
    let alternativeResults: [(MaterialType, Float)]
    
    var topAlternative: (MaterialType, Float)? {
        return alternativeResults.first
    }
}

/// Combined classification result
struct CombinedClassificationResult: Codable {
    let materialType: MaterialType
    let confidence: Float
    let combinationMethod: CombinationMethod
    
    var isReliable: Bool {
        return confidence > 0.8
    }
}

enum CombinationMethod: String, CaseIterable, Codable {
    case weighted = "weighted"
    case ensemble = "ensemble"
    case voting = "voting"
    case bayesian = "bayesian"
    
    var displayName: String {
        return rawValue.capitalized
    }
}

// MARK: - Hierarchical Classification

/// Hierarchical classification result
struct HierarchicalClassificationResult: Codable {
    let categoryResult: CategoryClassificationResult
    let materialResult: MaterialClassificationResult
    let propertyResults: [PropertyClassificationResult]
    let overallConfidence: Float
    
    var classificationPath: String {
        return "\(categoryResult.category.displayName) → \(materialResult.materialType.displayName)"
    }
}

struct CategoryClassificationResult: Codable {
    let category: MaterialCategory
    let confidence: Float
    let alternatives: [(MaterialCategory, Float)]
}

struct PropertyClassificationResult: Codable {
    let propertyType: PropertyType
    let value: Float
    let confidence: Float
}

enum PropertyType: String, CaseIterable, Codable {
    case hardness = "hardness"
    case reflectivity = "reflectivity"
    case porosity = "porosity"
    case roughness = "roughness"
    case density = "density"
    
    var displayName: String {
        return rawValue.capitalized
    }
}

// MARK: - Model Management

/// Material classification model information
struct MaterialClassificationModel: Identifiable, Codable {
    let id = UUID()
    let name: String
    let version: String
    let accuracy: Float
    let supportedMaterials: [MaterialType]
    let modelSize: Int // in bytes
    let lastUpdated: Date
    
    init(name: String, version: String, accuracy: Float) {
        self.name = name
        self.version = version
        self.accuracy = accuracy
        self.supportedMaterials = MaterialType.allCases
        self.modelSize = 0
        self.lastUpdated = Date()
    }
    
    var displayName: String {
        return "\(name) v\(version)"
    }
    
    var accuracyPercentage: String {
        return String(format: "%.1f%%", accuracy * 100)
    }
}

/// Model loading state
enum ModelLoadingState: Equatable {
    case notLoaded
    case loading
    case loaded
    case failed(Error)
    
    static func == (lhs: ModelLoadingState, rhs: ModelLoadingState) -> Bool {
        switch (lhs, rhs) {
        case (.notLoaded, .notLoaded), (.loading, .loading), (.loaded, .loaded):
            return true
        case (.failed, .failed):
            return true
        default:
            return false
        }
    }
    
    var displayName: String {
        switch self {
        case .notLoaded: return "Not Loaded"
        case .loading: return "Loading..."
        case .loaded: return "Loaded"
        case .failed: return "Failed"
        }
    }
}

// MARK: - Performance and Quality

/// Classification quality levels
enum ClassificationQuality: String, CaseIterable, Codable {
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
    
    var confidenceRange: ClosedRange<Float> {
        switch self {
        case .excellent: return 0.9...1.0
        case .good: return 0.8...0.9
        case .acceptable: return 0.7...0.8
        case .poor: return 0.0...0.7
        }
    }
}

/// Classification performance metrics
struct ClassificationMetrics: Codable {
    let averageConfidence: Float
    let totalClassifications: Int
    let averageProcessingTime: TimeInterval
    let classificationFrequency: Double
    let modelAccuracy: Float
    
    init() {
        self.averageConfidence = 0.0
        self.totalClassifications = 0
        self.averageProcessingTime = 0.0
        self.classificationFrequency = 0.0
        self.modelAccuracy = 0.0
    }
    
    init(averageConfidence: Float, totalClassifications: Int, averageProcessingTime: TimeInterval,
         classificationFrequency: Double, modelAccuracy: Float) {
        self.averageConfidence = averageConfidence
        self.totalClassifications = totalClassifications
        self.averageProcessingTime = averageProcessingTime
        self.classificationFrequency = classificationFrequency
        self.modelAccuracy = modelAccuracy
    }
    
    var performanceLevel: PerformanceLevel {
        let overallScore = (averageConfidence + modelAccuracy) / 2.0
        
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
}

// MARK: - Trends and Analysis

/// Classification trends over time
struct ClassificationTrends: Codable {
    let materialDistribution: [MaterialType: Float]
    let confidenceTrend: TrendDirection
    let accuracyTrend: TrendDirection
    let timeRange: ClosedRange<Date>
    
    var dominantMaterial: MaterialType? {
        return materialDistribution.max(by: { $0.value < $1.value })?.key
    }
    
    var materialDiversity: Float {
        let nonZeroValues = materialDistribution.values.filter { $0 > 0 }
        return Float(nonZeroValues.count) / Float(MaterialType.allCases.count)
    }
}

enum TrendDirection: String, CaseIterable, Codable {
    case improving = "improving"
    case stable = "stable"
    case degrading = "degrading"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var color: String {
        switch self {
        case .improving: return "green"
        case .stable: return "blue"
        case .degrading: return "red"
        }
    }
}

/// Classification frame for history tracking
struct ClassificationFrame: Codable {
    let result: MaterialClassificationResult
    let timestamp: Date
    
    var materialType: MaterialType {
        return result.materialType
    }
    
    var confidence: Float {
        return result.confidence
    }
    
    var region: CGRect {
        return result.region
    }
}

/// Performance metric for monitoring
struct PerformanceMetric: Codable {
    let metricType: MetricType
    let value: Float
    let timestamp: Date
    let context: String?
}

enum MetricType: String, CaseIterable, Codable {
    case confidence = "confidence"
    case processingTime = "processing_time"
    case accuracy = "accuracy"
    case throughput = "throughput"
    
    var displayName: String {
        switch self {
        case .confidence: return "Confidence"
        case .processingTime: return "Processing Time"
        case .accuracy: return "Accuracy"
        case .throughput: return "Throughput"
        }
    }
    
    var unit: String {
        switch self {
        case .confidence, .accuracy: return "%"
        case .processingTime: return "ms"
        case .throughput: return "fps"
        }
    }
}

// MARK: - Supporting Classes (Placeholder)

class FeatureExtractor {
    func extractFeatures(image: CVPixelBuffer, depthData: ARDepthData?, region: CGRect) async -> ClassificationFeatures {
        // Placeholder implementation
        return ClassificationFeatures(
            imageFeatures: ImageFeatures(
                featureVector: Array(repeating: 0.5, count: 128),
                colorHistogram: Array(repeating: 0.1, count: 64),
                edgeFeatures: Array(repeating: 0.3, count: 32),
                textureDescriptors: Array(repeating: 0.4, count: 64),
                averageColor: simd_float3(0.5, 0.5, 0.5),
                brightness: 0.5,
                contrast: 0.5
            ),
            depthFeatures: DepthFeatures(
                featureVector: Array(repeating: 0.5, count: 64),
                depthVariance: 0.1,
                surfaceRoughness: 0.2,
                depthGradients: Array(repeating: 0.3, count: 32),
                averageDepth: 2.0,
                depthRange: 1.0
            ),
            textureFeatures: TextureFeatures(
                featureVector: Array(repeating: 0.5, count: 96),
                lbpHistogram: Array(repeating: 0.1, count: 32),
                glcmFeatures: Array(repeating: 0.2, count: 16),
                gaborResponses: Array(repeating: 0.3, count: 24),
                waveletFeatures: Array(repeating: 0.4, count: 24)
            ),
            geometricFeatures: GeometricFeatures(
                featureVector: Array(repeating: 0.5, count: 48),
                curvature: 0.1,
                planarity: 0.9,
                normalVariation: 0.2,
                edgeDensity: 0.3
            ),
            surfaceNormals: [simd_float3(0, 1, 0)],
            extractionTimestamp: Date()
        )
    }
}

class EnsembleClassifier {
    func combineResults(primary: PrimaryClassificationResult, texture: TextureAnalysisResult,
                       surface: SurfacePropertyResult, features: ClassificationFeatures,
                       ensembleModel: MLModel) async -> CombinedClassificationResult {
        // Placeholder implementation
        return CombinedClassificationResult(
            materialType: primary.materialType,
            confidence: primary.confidence * 0.9,
            combinationMethod: .ensemble
        )
    }
}

class TemporalSmoother {
    func smoothResult(_ result: CombinedClassificationResult, history: [ClassificationFrame]) async -> CombinedClassificationResult {
        // Placeholder implementation
        return result
    }
}

class HierarchicalClassifier {
    func classifyHierarchical(image: CVPixelBuffer, depthData: ARDepthData?, region: CGRect,
                             models: [MLModel]) async -> HierarchicalClassificationResult? {
        // Placeholder implementation
        return HierarchicalClassificationResult(
            categoryResult: CategoryClassificationResult(
                category: .organic,
                confidence: 0.85,
                alternatives: [(.synthetic, 0.10), (.inorganic, 0.05)]
            ),
            materialResult: MaterialClassificationResult(
                materialType: .wood,
                confidence: 0.88,
                textureProperties: TextureAnalysisResult(textureType: .textured, roughness: 0.3, pattern: .organic, confidence: 0.8),
                surfaceProperties: SurfacePropertyResult(hardness: .medium, reflectivity: 0.3, porosity: 0.4, confidence: 0.85),
                features: ClassificationFeatures(
                    imageFeatures: ImageFeatures(featureVector: [], colorHistogram: [], edgeFeatures: [], textureDescriptors: [], averageColor: simd_float3(0.6, 0.4, 0.2), brightness: 0.5, contrast: 0.5),
                    depthFeatures: DepthFeatures(featureVector: [], depthVariance: 0.1, surfaceRoughness: 0.3, depthGradients: [], averageDepth: 2.0, depthRange: 1.0),
                    textureFeatures: TextureFeatures(featureVector: [], lbpHistogram: [], glcmFeatures: [], gaborResponses: [], waveletFeatures: []),
                    geometricFeatures: GeometricFeatures(featureVector: [], curvature: 0.1, planarity: 0.9, normalVariation: 0.2, edgeDensity: 0.3),
                    surfaceNormals: [],
                    extractionTimestamp: Date()
                ),
                region: region,
                timestamp: Date(),
                processingTime: 0.1
            ),
            propertyResults: [
                PropertyClassificationResult(propertyType: .hardness, value: 0.5, confidence: 0.8),
                PropertyClassificationResult(propertyType: .reflectivity, value: 0.3, confidence: 0.85)
            ],
            overallConfidence: 0.86
        )
    }
}

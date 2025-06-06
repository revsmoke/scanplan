import Foundation
import ARKit
import simd

// MARK: - Enhanced Plane Data Structures

/// Enhanced plane with sub-centimeter accuracy and advanced classification
struct EnhancedPlane: Identifiable, Codable {
    let id = UUID()
    let identifier: UUID
    let type: PlaneType
    let basicProperties: PlaneBasicProperties
    let surfaceClassification: SurfaceClassification
    let enhancedGeometry: EnhancedPlaneGeometry
    let qualityAssessment: PlaneQualityAssessment
    let detectionTimestamp: Date
    var lastUpdateTimestamp: Date
    
    // Derived properties
    var area: Float { enhancedGeometry.area }
    var perimeter: Float { enhancedGeometry.perimeter }
    var confidence: Float { qualityAssessment.overallQuality }
    var isHighQuality: Bool { qualityAssessment.meetsSubCentimeterAccuracy }
    
    var ageInSeconds: TimeInterval {
        return Date().timeIntervalSince(detectionTimestamp)
    }
    
    var timeSinceLastUpdate: TimeInterval {
        return Date().timeIntervalSince(lastUpdateTimestamp)
    }
}

/// Basic plane properties from ARKit
struct PlaneBasicProperties: Codable {
    let center: simd_float3
    let extent: simd_float3
    let transform: simd_float4x4
    let alignment: ARPlaneAnchor.Alignment
    let classification: ARPlaneAnchor.Classification
    let geometry: ARPlaneGeometry
    
    // Custom coding for ARKit types
    enum CodingKeys: String, CodingKey {
        case center, extent, transform
        case alignmentRawValue, classificationRawValue
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(center, forKey: .center)
        try container.encode(extent, forKey: .extent)
        try container.encode(transform, forKey: .transform)
        try container.encode(alignment.rawValue, forKey: .alignmentRawValue)
        try container.encode(classification.rawValue, forKey: .classificationRawValue)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        center = try container.decode(simd_float3.self, forKey: .center)
        extent = try container.decode(simd_float3.self, forKey: .extent)
        transform = try container.decode(simd_float4x4.self, forKey: .transform)
        
        let alignmentRaw = try container.decode(Int.self, forKey: .alignmentRawValue)
        alignment = ARPlaneAnchor.Alignment(rawValue: alignmentRaw) ?? .horizontal
        
        let classificationRaw = try container.decode(Int.self, forKey: .classificationRawValue)
        classification = ARPlaneAnchor.Classification(rawValue: classificationRaw) ?? .none
        
        // Note: ARPlaneGeometry cannot be easily serialized, would need custom handling
        geometry = ARPlaneGeometry() // Placeholder
    }
    
    init(center: simd_float3, extent: simd_float3, transform: simd_float4x4, 
         alignment: ARPlaneAnchor.Alignment, classification: ARPlaneAnchor.Classification, 
         geometry: ARPlaneGeometry) {
        self.center = center
        self.extent = extent
        self.transform = transform
        self.alignment = alignment
        self.classification = classification
        self.geometry = geometry
    }
}

/// Enhanced plane geometry with precise calculations
struct EnhancedPlaneGeometry: Codable {
    let vertices: [simd_float3]
    let area: Float
    let perimeter: Float
    let bounds: PlaneBounds
    let normal: simd_float3
    let curvature: Float
    
    var vertexCount: Int { vertices.count }
    var isFlat: Bool { curvature < 0.01 } // Less than 1cm deviation
    var aspectRatio: Float { 
        guard bounds.size.x > 0 else { return 1.0 }
        return bounds.size.z / bounds.size.x 
    }
}

/// Plane bounds in 3D space
struct PlaneBounds: Codable {
    let min: simd_float3
    let max: simd_float3
    let center: simd_float3
    let size: simd_float3
    
    var volume: Float { size.x * size.y * size.z }
    var footprint: Float { size.x * size.z }
    
    static func empty() -> PlaneBounds {
        return PlaneBounds(
            min: simd_float3(0, 0, 0),
            max: simd_float3(0, 0, 0),
            center: simd_float3(0, 0, 0),
            size: simd_float3(0, 0, 0)
        )
    }
}

/// Plane type classification
enum PlaneType: String, CaseIterable, Codable {
    case floor = "floor"
    case ceiling = "ceiling"
    case wall = "wall"
    case table = "table"
    case desk = "desk"
    case shelf = "shelf"
    case unknown = "unknown"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var isHorizontal: Bool {
        switch self {
        case .floor, .ceiling, .table, .desk, .shelf:
            return true
        case .wall:
            return false
        case .unknown:
            return false
        }
    }
    
    var isVertical: Bool {
        return !isHorizontal && self != .unknown
    }
    
    var typicalHeight: ClosedRange<Float>? {
        switch self {
        case .floor:
            return -0.5...0.1 // Floor level
        case .ceiling:
            return 2.0...4.0 // Ceiling height
        case .table:
            return 0.6...0.8 // Table height
        case .desk:
            return 0.7...0.9 // Desk height
        case .shelf:
            return 0.5...2.5 // Shelf range
        case .wall:
            return nil // Walls span full height
        case .unknown:
            return nil
        }
    }
}

/// Advanced surface classification
struct SurfaceClassification: Codable {
    let material: SurfaceMaterial
    let texture: SurfaceTexture
    let reflectance: Float // 0.0 - 1.0
    let roughness: Float // 0.0 - 1.0
    let confidence: Float // 0.0 - 1.0
    let classificationMethod: ClassificationMethod
    
    var isReflective: Bool { reflectance > 0.7 }
    var isSmooth: Bool { roughness < 0.3 }
    var isHighConfidence: Bool { confidence > 0.8 }
}

/// Surface material types
enum SurfaceMaterial: String, CaseIterable, Codable {
    case wood = "wood"
    case metal = "metal"
    case glass = "glass"
    case plastic = "plastic"
    case concrete = "concrete"
    case tile = "tile"
    case carpet = "carpet"
    case fabric = "fabric"
    case paper = "paper"
    case stone = "stone"
    case unknown = "unknown"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var typicalReflectance: ClosedRange<Float> {
        switch self {
        case .glass: return 0.8...0.95
        case .metal: return 0.6...0.9
        case .tile: return 0.4...0.8
        case .plastic: return 0.3...0.7
        case .wood: return 0.2...0.5
        case .concrete: return 0.2...0.4
        case .stone: return 0.1...0.4
        case .paper: return 0.7...0.9
        case .fabric, .carpet: return 0.1...0.3
        case .unknown: return 0.0...1.0
        }
    }
    
    var typicalRoughness: ClosedRange<Float> {
        switch self {
        case .glass: return 0.0...0.1
        case .metal: return 0.0...0.3
        case .tile: return 0.1...0.4
        case .plastic: return 0.1...0.5
        case .wood: return 0.3...0.7
        case .concrete: return 0.6...0.9
        case .stone: return 0.4...0.8
        case .paper: return 0.2...0.6
        case .fabric, .carpet: return 0.7...1.0
        case .unknown: return 0.0...1.0
        }
    }
}

/// Surface texture classification
enum SurfaceTexture: String, CaseIterable, Codable {
    case smooth = "smooth"
    case rough = "rough"
    case textured = "textured"
    case patterned = "patterned"
    case glossy = "glossy"
    case matte = "matte"
    case unknown = "unknown"
    
    var displayName: String {
        return rawValue.capitalized
    }
}

/// Classification method used
enum ClassificationMethod: String, CaseIterable, Codable {
    case arkit = "arkit"
    case vision = "vision"
    case lidar = "lidar"
    case combined = "combined"
    case manual = "manual"
    
    var displayName: String {
        switch self {
        case .arkit: return "ARKit"
        case .vision: return "Vision"
        case .lidar: return "LiDAR"
        case .combined: return "Combined"
        case .manual: return "Manual"
        }
    }
}

/// Plane quality assessment
struct PlaneQualityAssessment: Codable {
    let overallQuality: Float // 0.0 - 1.0
    let trackingConfidence: Float // 0.0 - 1.0
    let geometricConsistency: Float // 0.0 - 1.0
    let temporalStability: Float // 0.0 - 1.0
    let meetsSubCentimeterAccuracy: Bool
    
    var qualityLevel: QualityLevel {
        switch overallQuality {
        case 0.9...1.0: return .excellent
        case 0.8..<0.9: return .good
        case 0.7..<0.8: return .acceptable
        case 0.5..<0.7: return .poor
        default: return .unacceptable
        }
    }
    
    var isProfessionalGrade: Bool {
        return meetsSubCentimeterAccuracy && overallQuality > 0.8
    }
}

/// Quality level classification
enum QualityLevel: String, CaseIterable, Codable {
    case excellent = "excellent"
    case good = "good"
    case acceptable = "acceptable"
    case poor = "poor"
    case unacceptable = "unacceptable"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var color: String {
        switch self {
        case .excellent: return "green"
        case .good: return "blue"
        case .acceptable: return "yellow"
        case .poor: return "orange"
        case .unacceptable: return "red"
        }
    }
}

/// Performance metrics for plane detection
struct PlaneDetectionMetrics: Codable {
    let averageProcessingTime: TimeInterval
    let maxProcessingTime: TimeInterval
    let frameRate: Double
    let planesDetected: Int
    let meetsLatencyTarget: Bool
    
    init() {
        self.averageProcessingTime = 0.0
        self.maxProcessingTime = 0.0
        self.frameRate = 0.0
        self.planesDetected = 0
        self.meetsLatencyTarget = false
    }
    
    init(averageProcessingTime: TimeInterval, maxProcessingTime: TimeInterval, 
         frameRate: Double, planesDetected: Int, meetsLatencyTarget: Bool) {
        self.averageProcessingTime = averageProcessingTime
        self.maxProcessingTime = maxProcessingTime
        self.frameRate = frameRate
        self.planesDetected = planesDetected
        self.meetsLatencyTarget = meetsLatencyTarget
    }
    
    var performanceLevel: PerformanceLevel {
        if meetsLatencyTarget && frameRate > 30 {
            return .excellent
        } else if meetsLatencyTarget && frameRate > 20 {
            return .good
        } else if frameRate > 15 {
            return .acceptable
        } else {
            return .poor
        }
    }
}

/// Performance level classification
enum PerformanceLevel: String, CaseIterable {
    case excellent = "excellent"
    case good = "good"
    case acceptable = "acceptable"
    case poor = "poor"
    
    var displayName: String {
        return rawValue.capitalized
    }
}

// MARK: - Motion Validation Data Structures

/// Motion-based validation result
struct MotionValidationResult: Codable {
    let isValid: Bool
    let confidence: Float
    let motionConsistency: Float
    let stabilityScore: Float
    let validationMethod: MotionValidationMethod
    let issues: [MotionValidationIssue]
    let timestamp: Date
}

/// Motion validation method
enum MotionValidationMethod: String, CaseIterable, Codable {
    case deviceMotion = "device_motion"
    case visualInertial = "visual_inertial"
    case multiFrame = "multi_frame"
    case combined = "combined"
}

/// Motion validation issue
struct MotionValidationIssue: Codable {
    let type: MotionIssueType
    let severity: MotionIssueSeverity
    let description: String
}

enum MotionIssueType: String, CaseIterable, Codable {
    case excessiveMotion = "excessive_motion"
    case inconsistentTracking = "inconsistent_tracking"
    case lowStability = "low_stability"
    case calibrationDrift = "calibration_drift"
}

enum MotionIssueSeverity: String, CaseIterable, Codable {
    case critical = "critical"
    case major = "major"
    case minor = "minor"
    case warning = "warning"
}

// MARK: - Real-Time Tracking Data Structures

/// Real-time plane tracking data
struct PlaneTrackingData: Codable {
    let planeId: UUID
    let currentTransform: simd_float4x4
    let velocity: simd_float3
    let acceleration: simd_float3
    let trackingQuality: TrackingQuality
    let lastUpdateTime: Date
    let trackingHistory: [TrackingSnapshot]
}

/// Tracking quality assessment
enum TrackingQuality: String, CaseIterable, Codable {
    case excellent = "excellent"
    case good = "good"
    case limited = "limited"
    case lost = "lost"
    
    var displayName: String {
        return rawValue.capitalized
    }
}

/// Tracking snapshot for history
struct TrackingSnapshot: Codable {
    let timestamp: Date
    let transform: simd_float4x4
    let confidence: Float
}

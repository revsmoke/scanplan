import Foundation
import RoomPlan
import ARKit
import simd

// MARK: - Core Data Structures for Multi-Room Scanning

/// Represents the current state of the multi-room scanning session
enum ScanningState: Equatable {
    case idle
    case scanning
    case paused
    case processing
    case completed
    case error(String)
    
    var isActive: Bool {
        switch self {
        case .scanning, .processing:
            return true
        default:
            return false
        }
    }
    
    var displayName: String {
        switch self {
        case .idle:
            return "Ready"
        case .scanning:
            return "Scanning"
        case .paused:
            return "Paused"
        case .processing:
            return "Processing"
        case .completed:
            return "Completed"
        case .error(let message):
            return "Error: \(message)"
        }
    }
}

/// Container for captured room data with spatial context
struct CapturedRoomData: Identifiable, Codable {
    let id = UUID()
    let index: Int
    let startTime: Date
    var endTime: Date?
    var capturedRoom: CapturedRoom?
    var spatialContext: SpatialContext
    var roomBoundary: RoomBoundary?
    var qualityMetrics: RoomQualityMetrics?
    
    init(index: Int, startTime: Date, spatialContext: SpatialContext) {
        self.index = index
        self.startTime = startTime
        self.spatialContext = spatialContext
    }
    
    var scanDuration: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }
    
    var isComplete: Bool {
        return capturedRoom != nil && endTime != nil
    }
}

/// Spatial context information for room alignment
struct SpatialContext: Codable {
    let worldTransform: simd_float4x4
    let timestamp: Date
    let confidence: Float
    var trackingState: ARCamera.TrackingState?
    var featurePoints: Int?
    
    init(worldTransform: simd_float4x4, timestamp: Date, confidence: Float) {
        self.worldTransform = worldTransform
        self.timestamp = timestamp
        self.confidence = confidence
    }
}

/// Represents a transition between rooms with spatial relationship
struct RoomTransition: Identifiable, Codable {
    let id = UUID()
    let fromRoomIndex: Int
    let toRoomIndex: Int
    let spatialTransform: simd_float4x4
    let timestamp: Date
    var connectionType: ConnectionType = .unknown
    var confidence: Float = 0.0
    
    enum ConnectionType: String, Codable, CaseIterable {
        case door = "door"
        case opening = "opening"
        case hallway = "hallway"
        case stairway = "stairway"
        case unknown = "unknown"
        
        var displayName: String {
            switch self {
            case .door: return "Door"
            case .opening: return "Opening"
            case .hallway: return "Hallway"
            case .stairway: return "Stairway"
            case .unknown: return "Unknown"
            }
        }
    }
}

/// Session continuity data for maintaining spatial context
struct SessionContinuityData {
    let previousRoomIndex: Int
    let spatialAnchor: ARAnchor?
    let worldTransform: simd_float4x4
    let timestamp: Date = Date()
    var isValid: Bool = true
    
    init(previousRoomIndex: Int, spatialAnchor: ARAnchor?, worldTransform: simd_float4x4) {
        self.previousRoomIndex = previousRoomIndex
        self.spatialAnchor = spatialAnchor
        self.worldTransform = worldTransform
    }
}

/// Spatial alignment data for multi-room coordination
struct SpatialAlignmentData {
    let rooms: [CapturedRoomData]
    let transitions: [RoomTransition]
    let alignmentQuality: AlignmentQuality
    let timestamp: Date = Date()
    var globalCoordinateSystem: GlobalCoordinateSystem?
    
    var totalRooms: Int {
        return rooms.count
    }
    
    var validTransitions: [RoomTransition] {
        return transitions.filter { $0.confidence > 0.5 }
    }
}

/// Quality assessment for room-to-room alignment
struct AlignmentQuality: Codable {
    let overallScore: Float
    let roomAlignmentScores: [Float]
    let issues: [String]
    let timestamp: Date = Date()
    
    var qualityLevel: QualityLevel {
        switch overallScore {
        case 0.9...1.0:
            return .excellent
        case 0.8..<0.9:
            return .good
        case 0.7..<0.8:
            return .fair
        case 0.6..<0.7:
            return .poor
        default:
            return .unacceptable
        }
    }
    
    enum QualityLevel: String, CaseIterable {
        case excellent = "excellent"
        case good = "good"
        case fair = "fair"
        case poor = "poor"
        case unacceptable = "unacceptable"
        
        var displayName: String {
            return rawValue.capitalized
        }
        
        var color: String {
            switch self {
            case .excellent: return "green"
            case .good: return "blue"
            case .fair: return "yellow"
            case .poor: return "orange"
            case .unacceptable: return "red"
            }
        }
    }
}

/// Room boundary definition for spatial understanding
struct RoomBoundary: Codable {
    let vertices: [simd_float3]
    let center: simd_float3
    let area: Float
    let perimeter: Float
    
    init(vertices: [simd_float3]) {
        self.vertices = vertices
        self.center = RoomBoundary.calculateCenter(vertices)
        self.area = RoomBoundary.calculateArea(vertices)
        self.perimeter = RoomBoundary.calculatePerimeter(vertices)
    }
    
    private static func calculateCenter(_ vertices: [simd_float3]) -> simd_float3 {
        guard !vertices.isEmpty else { return simd_float3(0, 0, 0) }
        
        let sum = vertices.reduce(simd_float3(0, 0, 0)) { $0 + $1 }
        return sum / Float(vertices.count)
    }
    
    private static func calculateArea(_ vertices: [simd_float3]) -> Float {
        guard vertices.count >= 3 else { return 0.0 }
        
        // Simple polygon area calculation (assuming planar polygon)
        var area: Float = 0.0
        for i in 0..<vertices.count {
            let j = (i + 1) % vertices.count
            area += vertices[i].x * vertices[j].z - vertices[j].x * vertices[i].z
        }
        return abs(area) / 2.0
    }
    
    private static func calculatePerimeter(_ vertices: [simd_float3]) -> Float {
        guard vertices.count >= 2 else { return 0.0 }
        
        var perimeter: Float = 0.0
        for i in 0..<vertices.count {
            let j = (i + 1) % vertices.count
            perimeter += simd_distance(vertices[i], vertices[j])
        }
        return perimeter
    }
}

/// Quality metrics for individual room scans
struct RoomQualityMetrics: Codable {
    let completeness: Float // 0.0 - 1.0
    let accuracy: Float // 0.0 - 1.0
    let consistency: Float // 0.0 - 1.0
    let featureCount: Int
    let scanDuration: TimeInterval
    
    var overallQuality: Float {
        return (completeness + accuracy + consistency) / 3.0
    }
    
    var qualityLevel: AlignmentQuality.QualityLevel {
        switch overallQuality {
        case 0.9...1.0: return .excellent
        case 0.8..<0.9: return .good
        case 0.7..<0.8: return .fair
        case 0.6..<0.7: return .poor
        default: return .unacceptable
        }
    }
}

/// Global coordinate system for multi-room alignment
struct GlobalCoordinateSystem {
    let origin: simd_float3
    let orientation: simd_quatf
    let scale: Float
    let timestamp: Date = Date()
    
    init(origin: simd_float3 = simd_float3(0, 0, 0), 
         orientation: simd_quatf = simd_quatf(ix: 0, iy: 0, iz: 0, r: 1), 
         scale: Float = 1.0) {
        self.origin = origin
        self.orientation = orientation
        self.scale = scale
    }
    
    func transform(_ point: simd_float3) -> simd_float3 {
        // Apply global coordinate transformation
        let rotated = simd_act(orientation, point)
        return origin + (rotated * scale)
    }
}

/// Combined building model representing all scanned rooms
struct CombinedBuildingModel {
    let rooms: [CapturedRoomData]
    let globalCoordinateSystem: GlobalCoordinateSystem
    let alignmentQuality: AlignmentQuality
    let buildingMetrics: BuildingMetrics
    let timestamp: Date = Date()
    
    init(rooms: [CapturedRoomData], 
         globalCoordinateSystem: GlobalCoordinateSystem, 
         alignmentQuality: AlignmentQuality) {
        self.rooms = rooms
        self.globalCoordinateSystem = globalCoordinateSystem
        self.alignmentQuality = alignmentQuality
        self.buildingMetrics = BuildingMetrics(rooms: rooms)
    }
}

/// Overall building metrics derived from all rooms
struct BuildingMetrics {
    let totalFloorArea: Float
    let totalVolume: Float
    let roomCount: Int
    let averageRoomSize: Float
    let buildingBounds: BoundingBox
    
    init(rooms: [CapturedRoomData]) {
        self.roomCount = rooms.count
        
        // Calculate metrics from room data
        var totalArea: Float = 0.0
        var totalVol: Float = 0.0
        
        for room in rooms {
            if let boundary = room.roomBoundary {
                totalArea += boundary.area
                // Estimate volume (area * average ceiling height)
                totalVol += boundary.area * 2.5 // Assume 2.5m ceiling
            }
        }
        
        self.totalFloorArea = totalArea
        self.totalVolume = totalVol
        self.averageRoomSize = roomCount > 0 ? totalArea / Float(roomCount) : 0.0
        self.buildingBounds = BoundingBox(rooms: rooms)
    }
}

/// 3D bounding box for the entire building
struct BoundingBox {
    let min: simd_float3
    let max: simd_float3
    
    init(rooms: [CapturedRoomData]) {
        var minPoint = simd_float3(Float.greatestFiniteMagnitude, 
                                  Float.greatestFiniteMagnitude, 
                                  Float.greatestFiniteMagnitude)
        var maxPoint = simd_float3(-Float.greatestFiniteMagnitude, 
                                  -Float.greatestFiniteMagnitude, 
                                  -Float.greatestFiniteMagnitude)
        
        for room in rooms {
            if let boundary = room.roomBoundary {
                for vertex in boundary.vertices {
                    minPoint = simd_min(minPoint, vertex)
                    maxPoint = simd_max(maxPoint, vertex)
                }
            }
        }
        
        self.min = minPoint
        self.max = maxPoint
    }
    
    var size: simd_float3 {
        return max - min
    }
    
    var center: simd_float3 {
        return (min + max) / 2.0
    }
}

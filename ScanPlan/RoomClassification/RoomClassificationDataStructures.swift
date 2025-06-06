import Foundation
import RoomPlan
import simd

// MARK: - Room Classification Results

/// Result of room type classification with confidence and features
struct RoomClassificationResult: Identifiable, Codable {
    let id = UUID()
    let roomType: RoomType
    let confidence: Float
    let features: CombinedFeatures
    let timestamp: Date
    let alternativeTypes: [RoomTypeCandidate]?
    
    init(roomType: RoomType, confidence: Float, features: CombinedFeatures, timestamp: Date, alternativeTypes: [RoomTypeCandidate]? = nil) {
        self.roomType = roomType
        self.confidence = confidence
        self.features = features
        self.timestamp = timestamp
        self.alternativeTypes = alternativeTypes
    }
    
    static func unknown() -> RoomClassificationResult {
        return RoomClassificationResult(
            roomType: .unknown,
            confidence: 0.0,
            features: CombinedFeatures.empty(),
            timestamp: Date()
        )
    }
    
    static func error(_ message: String) -> RoomClassificationResult {
        return RoomClassificationResult(
            roomType: .unknown,
            confidence: 0.0,
            features: CombinedFeatures.empty(),
            timestamp: Date()
        )
    }
    
    var qualityLevel: ClassificationQuality {
        switch confidence {
        case 0.9...1.0: return .excellent
        case 0.8..<0.9: return .good
        case 0.7..<0.8: return .fair
        case 0.5..<0.7: return .poor
        default: return .unreliable
        }
    }
}

/// Alternative room type candidates with confidence scores
struct RoomTypeCandidate: Codable {
    let roomType: RoomType
    let confidence: Float
    let reasoning: String?
}

/// Quality assessment for classification results
enum ClassificationQuality: String, CaseIterable {
    case excellent = "excellent"
    case good = "good"
    case fair = "fair"
    case poor = "poor"
    case unreliable = "unreliable"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var color: String {
        switch self {
        case .excellent: return "green"
        case .good: return "blue"
        case .fair: return "yellow"
        case .poor: return "orange"
        case .unreliable: return "red"
        }
    }
}

// MARK: - Room Types

/// Comprehensive room type classification for architectural use
enum RoomType: String, CaseIterable, Codable {
    // Residential Rooms
    case livingRoom = "living_room"
    case bedroom = "bedroom"
    case kitchen = "kitchen"
    case bathroom = "bathroom"
    case diningRoom = "dining_room"
    case familyRoom = "family_room"
    case office = "office"
    case library = "library"
    case laundryRoom = "laundry_room"
    case pantry = "pantry"
    case closet = "closet"
    case entryway = "entryway"
    case hallway = "hallway"
    case stairway = "stairway"
    case garage = "garage"
    case basement = "basement"
    case attic = "attic"
    
    // Commercial Spaces
    case conferenceRoom = "conference_room"
    case reception = "reception"
    case lobby = "lobby"
    case retail = "retail"
    case restaurant = "restaurant"
    case classroom = "classroom"
    case laboratory = "laboratory"
    case workshop = "workshop"
    case warehouse = "warehouse"
    case serverRoom = "server_room"
    
    // Specialized Spaces
    case gym = "gym"
    case theater = "theater"
    case studio = "studio"
    case clinic = "clinic"
    case chapel = "chapel"
    
    // Utility and Service
    case mechanicalRoom = "mechanical_room"
    case electricalRoom = "electrical_room"
    case janitorCloset = "janitor_closet"
    case storageRoom = "storage_room"
    
    // Unknown
    case unknown = "unknown"
    
    var displayName: String {
        switch self {
        case .livingRoom: return "Living Room"
        case .bedroom: return "Bedroom"
        case .kitchen: return "Kitchen"
        case .bathroom: return "Bathroom"
        case .diningRoom: return "Dining Room"
        case .familyRoom: return "Family Room"
        case .office: return "Office"
        case .library: return "Library"
        case .laundryRoom: return "Laundry Room"
        case .pantry: return "Pantry"
        case .closet: return "Closet"
        case .entryway: return "Entryway"
        case .hallway: return "Hallway"
        case .stairway: return "Stairway"
        case .garage: return "Garage"
        case .basement: return "Basement"
        case .attic: return "Attic"
        case .conferenceRoom: return "Conference Room"
        case .reception: return "Reception"
        case .lobby: return "Lobby"
        case .retail: return "Retail"
        case .restaurant: return "Restaurant"
        case .classroom: return "Classroom"
        case .laboratory: return "Laboratory"
        case .workshop: return "Workshop"
        case .warehouse: return "Warehouse"
        case .serverRoom: return "Server Room"
        case .gym: return "Gym"
        case .theater: return "Theater"
        case .studio: return "Studio"
        case .clinic: return "Clinic"
        case .chapel: return "Chapel"
        case .mechanicalRoom: return "Mechanical Room"
        case .electricalRoom: return "Electrical Room"
        case .janitorCloset: return "Janitor Closet"
        case .storageRoom: return "Storage Room"
        case .unknown: return "Unknown"
        }
    }
    
    var category: RoomCategory {
        switch self {
        case .livingRoom, .bedroom, .kitchen, .bathroom, .diningRoom, .familyRoom, .office, .library, .laundryRoom, .pantry, .closet, .entryway:
            return .residential
        case .hallway, .stairway:
            return .circulation
        case .garage, .basement, .attic, .storageRoom:
            return .utility
        case .conferenceRoom, .reception, .lobby, .retail, .restaurant, .classroom, .laboratory, .workshop, .warehouse, .serverRoom:
            return .commercial
        case .gym, .theater, .studio, .clinic, .chapel:
            return .specialized
        case .mechanicalRoom, .electricalRoom, .janitorCloset:
            return .service
        case .unknown:
            return .unknown
        }
    }
}

/// High-level room categories
enum RoomCategory: String, CaseIterable {
    case residential = "residential"
    case commercial = "commercial"
    case circulation = "circulation"
    case utility = "utility"
    case service = "service"
    case specialized = "specialized"
    case unknown = "unknown"
    
    var displayName: String {
        return rawValue.capitalized
    }
}

// MARK: - Feature Structures

/// Combined features for room classification
struct CombinedFeatures: Codable {
    let geometry: GeometryFeatures
    let furniture: FurnitureFeatures
    let spatial: SpatialFeatures
    
    static func empty() -> CombinedFeatures {
        return CombinedFeatures(
            geometry: GeometryFeatures.empty(),
            furniture: FurnitureFeatures.empty(),
            spatial: SpatialFeatures.empty()
        )
    }
}

/// Geometric features of the room
struct GeometryFeatures: Codable {
    let floorArea: Float
    let volume: Float
    let aspectRatio: Float
    let wallCount: Int
    let openingCount: Int
    let shapeComplexity: Float
    let ceilingHeight: Float
    
    static func empty() -> GeometryFeatures {
        return GeometryFeatures(
            floorArea: 0.0,
            volume: 0.0,
            aspectRatio: 1.0,
            wallCount: 4,
            openingCount: 0,
            shapeComplexity: 1.0,
            ceilingHeight: 2.5
        )
    }
}

/// Furniture-related features
struct FurnitureFeatures: Codable {
    let furnitureCount: Int
    let furnitureTypes: [CapturedRoom.Object.Category]
    let furnitureDensity: Float
    let layoutPattern: FurnitureLayoutPattern
    let furnitureCoverage: Float
    
    static func empty() -> FurnitureFeatures {
        return FurnitureFeatures(
            furnitureCount: 0,
            furnitureTypes: [],
            furnitureDensity: 0.0,
            layoutPattern: .minimal,
            furnitureCoverage: 0.0
        )
    }
}

/// Spatial and functional features
struct SpatialFeatures: Codable {
    let connectivityScore: Float
    let lightingScore: Float
    let circulationScore: Float
    let accessibilityScore: Float
    
    static func empty() -> SpatialFeatures {
        return SpatialFeatures(
            connectivityScore: 0.0,
            lightingScore: 0.0,
            circulationScore: 1.0,
            accessibilityScore: 0.5
        )
    }
}

/// Furniture layout patterns
enum FurnitureLayoutPattern: String, CaseIterable, Codable {
    case minimal = "minimal"
    case moderate = "moderate"
    case dense = "dense"
    case clustered = "clustered"
    case distributed = "distributed"
    case perimeter = "perimeter"
    case central = "central"
    
    var displayName: String {
        return rawValue.capitalized
    }
}

// MARK: - Enhanced Furniture Objects

/// Enhanced furniture object with detailed properties
struct EnhancedFurnitureObject: Identifiable, Codable {
    let id = UUID()
    let baseObject: CapturedRoom.Object
    let materialType: MaterialType
    let condition: ObjectCondition
    let architecturalSignificance: ArchitecturalSignificance
    let enhancedProperties: ObjectFeatures
    let timestamp: Date = Date()
    
    static func fromBasicObject(_ object: CapturedRoom.Object) -> EnhancedFurnitureObject {
        return EnhancedFurnitureObject(
            baseObject: object,
            materialType: .unknown,
            condition: .unknown,
            architecturalSignificance: .low,
            enhancedProperties: ObjectFeatures(
                dimensions: object.dimensions,
                category: object.category,
                confidence: object.confidence
            )
        )
    }
    
    var estimatedValue: ObjectValue {
        // Estimate object value based on material, condition, and significance
        switch (materialType, condition, architecturalSignificance) {
        case (.wood, .excellent, .high), (.metal, .excellent, .high):
            return .high
        case (.wood, .good, .medium), (.fabric, .excellent, .medium):
            return .medium
        default:
            return .low
        }
    }
}

/// Object features for enhanced analysis
struct ObjectFeatures: Codable {
    let dimensions: simd_float3
    let category: CapturedRoom.Object.Category
    let confidence: Float
    let estimatedWeight: Float?
    let surfaceArea: Float?
    let volume: Float?
    
    init(dimensions: simd_float3, category: CapturedRoom.Object.Category, confidence: Float) {
        self.dimensions = dimensions
        self.category = category
        self.confidence = confidence
        self.estimatedWeight = nil
        self.surfaceArea = nil
        self.volume = nil
    }
}

/// Material types for classification
enum MaterialType: String, CaseIterable, Codable {
    case wood = "wood"
    case metal = "metal"
    case fabric = "fabric"
    case leather = "leather"
    case plastic = "plastic"
    case glass = "glass"
    case ceramic = "ceramic"
    case stone = "stone"
    case concrete = "concrete"
    case drywall = "drywall"
    case tile = "tile"
    case carpet = "carpet"
    case hardwood = "hardwood"
    case laminate = "laminate"
    case vinyl = "vinyl"
    case unknown = "unknown"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var category: MaterialCategory {
        switch self {
        case .wood, .hardwood, .laminate:
            return .organic
        case .metal:
            return .metallic
        case .fabric, .leather, .carpet:
            return .textile
        case .plastic, .vinyl:
            return .synthetic
        case .glass, .ceramic, .tile:
            return .ceramic
        case .stone, .concrete:
            return .masonry
        case .drywall:
            return .composite
        case .unknown:
            return .unknown
        }
    }
}

/// Material categories
enum MaterialCategory: String, CaseIterable {
    case organic = "organic"
    case metallic = "metallic"
    case textile = "textile"
    case synthetic = "synthetic"
    case ceramic = "ceramic"
    case masonry = "masonry"
    case composite = "composite"
    case unknown = "unknown"
}

/// Object condition assessment
enum ObjectCondition: String, CaseIterable, Codable {
    case excellent = "excellent"
    case good = "good"
    case fair = "fair"
    case poor = "poor"
    case damaged = "damaged"
    case unknown = "unknown"
    
    var displayName: String {
        return rawValue.capitalized
    }
}

/// Architectural significance of objects
enum ArchitecturalSignificance: String, CaseIterable, Codable {
    case high = "high"        // Built-in features, architectural elements
    case medium = "medium"    // Large furniture, fixtures
    case low = "low"          // Movable furniture, decorative items
    
    var displayName: String {
        return rawValue.capitalized
    }
}

/// Object value estimation
enum ObjectValue: String, CaseIterable {
    case high = "high"
    case medium = "medium"
    case low = "low"
    
    var displayName: String {
        return rawValue.capitalized
    }
}

// MARK: - Material Classification Map

/// Map of materials classified for different surfaces in a room
struct MaterialClassificationMap: Codable {
    private var wallMaterials: [UUID: MaterialType] = [:]
    private var floorMaterials: [UUID: MaterialType] = [:]
    private var ceilingMaterials: [UUID: MaterialType] = [:]
    
    mutating func addWallMaterial(_ wallId: UUID, material: MaterialType) {
        wallMaterials[wallId] = material
    }
    
    mutating func addFloorMaterial(_ floorId: UUID, material: MaterialType) {
        floorMaterials[floorId] = material
    }
    
    mutating func addCeilingMaterial(_ ceilingId: UUID, material: MaterialType) {
        ceilingMaterials[ceilingId] = material
    }
    
    func getWallMaterial(_ wallId: UUID) -> MaterialType? {
        return wallMaterials[wallId]
    }
    
    func getFloorMaterial(_ floorId: UUID) -> MaterialType? {
        return floorMaterials[floorId]
    }
    
    func getCeilingMaterial(_ ceilingId: UUID) -> MaterialType? {
        return ceilingMaterials[ceilingId]
    }
    
    var allMaterials: [MaterialType] {
        let all = Array(wallMaterials.values) + Array(floorMaterials.values) + Array(ceilingMaterials.values)
        return Array(Set(all))
    }
    
    var materialSummary: [MaterialType: Int] {
        let all = allMaterials
        var summary: [MaterialType: Int] = [:]
        
        for material in all {
            summary[material, default: 0] += 1
        }
        
        return summary
    }
}

import Foundation
import CoreData
import CloudKit

// MARK: - Core Data Entity Extensions

/// Multi-room project entity for Core Data persistence
@objc(MultiRoomProject)
public class MultiRoomProject: NSManagedObject {
    
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var projectDescription: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var version: Int32
    @NSManaged public var isCompleted: Bool
    @NSManaged public var totalFloorArea: Float
    @NSManaged public var totalVolume: Float
    @NSManaged public var buildingType: String?
    @NSManaged public var clientName: String?
    @NSManaged public var architectName: String?
    @NSManaged public var projectNotes: String?
    
    // Relationships
    @NSManaged public var rooms: NSSet?
    @NSManaged public var transitions: NSSet?
    @NSManaged public var collaborators: NSSet?
    
    // CloudKit integration
    @NSManaged public var ckRecordID: CKRecord.ID?
    @NSManaged public var ckRecordSystemFields: Data?
}

// MARK: - MultiRoomProject Core Data Extensions

extension MultiRoomProject {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<MultiRoomProject> {
        return NSFetchRequest<MultiRoomProject>(entityName: "MultiRoomProject")
    }
    
    public var roomsArray: [MultiRoomEntity] {
        let set = rooms as? Set<MultiRoomEntity> ?? []
        return set.sorted { $0.roomIndex < $1.roomIndex }
    }
    
    public var transitionsArray: [RoomTransitionEntity] {
        let set = transitions as? Set<RoomTransitionEntity> ?? []
        return set.sorted { $0.timestamp ?? Date() < $1.timestamp ?? Date() }
    }
    
    public var collaboratorsArray: [ProjectCollaborator] {
        let set = collaborators as? Set<ProjectCollaborator> ?? []
        return set.sorted { ($0.name ?? "") < ($1.name ?? "") }
    }
    
    public var roomCount: Int {
        return rooms?.count ?? 0
    }
    
    public var completionPercentage: Float {
        guard roomCount > 0 else { return 0.0 }
        
        let completedRooms = roomsArray.filter { $0.isCompleted }
        return Float(completedRooms.count) / Float(roomCount)
    }
}

// MARK: - Generated accessors for MultiRoomProject.rooms

extension MultiRoomProject {
    
    @objc(addRoomsObject:)
    @NSManaged public func addToRooms(_ value: MultiRoomEntity)
    
    @objc(removeRoomsObject:)
    @NSManaged public func removeFromRooms(_ value: MultiRoomEntity)
    
    @objc(addRooms:)
    @NSManaged public func addToRooms(_ values: NSSet)
    
    @objc(removeRooms:)
    @NSManaged public func removeFromRooms(_ values: NSSet)
}

// MARK: - Generated accessors for MultiRoomProject.transitions

extension MultiRoomProject {
    
    @objc(addTransitionsObject:)
    @NSManaged public func addToTransitions(_ value: RoomTransitionEntity)
    
    @objc(removeTransitionsObject:)
    @NSManaged public func removeFromTransitions(_ value: RoomTransitionEntity)
    
    @objc(addTransitions:)
    @NSManaged public func addToTransitions(_ values: NSSet)
    
    @objc(removeTransitions:)
    @NSManaged public func removeFromTransitions(_ values: NSSet)
}

// MARK: - Individual Room Entity

/// Individual room entity for Core Data persistence
@objc(MultiRoomEntity)
public class MultiRoomEntity: NSManagedObject {
    
    @NSManaged public var id: UUID?
    @NSManaged public var roomIndex: Int32
    @NSManaged public var roomName: String?
    @NSManaged public var roomType: String?
    @NSManaged public var startTime: Date?
    @NSManaged public var endTime: Date?
    @NSManaged public var isCompleted: Bool
    @NSManaged public var floorArea: Float
    @NSManaged public var volume: Float
    @NSManaged public var ceilingHeight: Float
    @NSManaged public var perimeter: Float
    
    // File paths for exported data
    @NSManaged public var usdzFilePath: String?
    @NSManaged public var jsonFilePath: String?
    @NSManaged public var thumbnailImagePath: String?
    
    // Encoded data
    @NSManaged public var spatialContextData: Data?
    @NSManaged public var qualityMetricsData: Data?
    @NSManaged public var roomBoundaryData: Data?
    
    // Relationships
    @NSManaged public var project: MultiRoomProject?
    @NSManaged public var measurements: NSSet?
    @NSManaged public var annotations: NSSet?
    
    // CloudKit integration
    @NSManaged public var ckRecordID: CKRecord.ID?
    @NSManaged public var ckRecordSystemFields: Data?
}

// MARK: - MultiRoomEntity Core Data Extensions

extension MultiRoomEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<MultiRoomEntity> {
        return NSFetchRequest<MultiRoomEntity>(entityName: "MultiRoomEntity")
    }
    
    public var scanDuration: TimeInterval? {
        guard let start = startTime, let end = endTime else { return nil }
        return end.timeIntervalSince(start)
    }
    
    public var spatialContext: SpatialContext? {
        guard let data = spatialContextData else { return nil }
        return try? JSONDecoder().decode(SpatialContext.self, from: data)
    }
    
    public var qualityMetrics: RoomQualityMetrics? {
        guard let data = qualityMetricsData else { return nil }
        return try? JSONDecoder().decode(RoomQualityMetrics.self, from: data)
    }
    
    public var roomBoundary: RoomBoundary? {
        guard let data = roomBoundaryData else { return nil }
        return try? JSONDecoder().decode(RoomBoundary.self, from: data)
    }
    
    public var measurementsArray: [RoomMeasurement] {
        let set = measurements as? Set<RoomMeasurement> ?? []
        return set.sorted { ($0.timestamp ?? Date()) < ($1.timestamp ?? Date()) }
    }
    
    public var annotationsArray: [RoomAnnotation] {
        let set = annotations as? Set<RoomAnnotation> ?? []
        return set.sorted { ($0.timestamp ?? Date()) < ($1.timestamp ?? Date()) }
    }
}

// MARK: - Room Transition Entity

/// Room transition entity for Core Data persistence
@objc(RoomTransitionEntity)
public class RoomTransitionEntity: NSManagedObject {
    
    @NSManaged public var id: UUID?
    @NSManaged public var fromRoomIndex: Int32
    @NSManaged public var toRoomIndex: Int32
    @NSManaged public var connectionType: String?
    @NSManaged public var confidence: Float
    @NSManaged public var timestamp: Date?
    @NSManaged public var spatialTransformData: Data?
    @NSManaged public var notes: String?
    
    // Relationships
    @NSManaged public var project: MultiRoomProject?
    
    // CloudKit integration
    @NSManaged public var ckRecordID: CKRecord.ID?
    @NSManaged public var ckRecordSystemFields: Data?
}

// MARK: - RoomTransitionEntity Core Data Extensions

extension RoomTransitionEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<RoomTransitionEntity> {
        return NSFetchRequest<RoomTransitionEntity>(entityName: "RoomTransitionEntity")
    }
    
    public var spatialTransform: simd_float4x4? {
        guard let data = spatialTransformData else { return nil }
        return data.withUnsafeBytes { bytes in
            bytes.bindMemory(to: simd_float4x4.self).first
        }
    }
    
    public func setSpatialTransform(_ transform: simd_float4x4) {
        spatialTransformData = Data(bytes: &transform, count: MemoryLayout<simd_float4x4>.size)
    }
}

// MARK: - Project Collaborator Entity

/// Project collaborator entity for team collaboration
@objc(ProjectCollaborator)
public class ProjectCollaborator: NSManagedObject {
    
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var email: String?
    @NSManaged public var role: String?
    @NSManaged public var permissions: String?
    @NSManaged public var joinedAt: Date?
    @NSManaged public var lastActiveAt: Date?
    @NSManaged public var isActive: Bool
    
    // Relationships
    @NSManaged public var project: MultiRoomProject?
    
    // CloudKit integration
    @NSManaged public var ckRecordID: CKRecord.ID?
    @NSManaged public var ckRecordSystemFields: Data?
}

// MARK: - ProjectCollaborator Core Data Extensions

extension ProjectCollaborator {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ProjectCollaborator> {
        return NSFetchRequest<ProjectCollaborator>(entityName: "ProjectCollaborator")
    }
    
    public enum Role: String, CaseIterable {
        case architect = "architect"
        case drafter = "drafter"
        case client = "client"
        case contractor = "contractor"
        case viewer = "viewer"
        
        public var displayName: String {
            return rawValue.capitalized
        }
        
        public var permissions: [Permission] {
            switch self {
            case .architect:
                return [.read, .write, .delete, .share, .export]
            case .drafter:
                return [.read, .write, .export]
            case .contractor:
                return [.read, .write, .export]
            case .client:
                return [.read, .export]
            case .viewer:
                return [.read]
            }
        }
    }
    
    public enum Permission: String, CaseIterable {
        case read = "read"
        case write = "write"
        case delete = "delete"
        case share = "share"
        case export = "export"
    }
}

// MARK: - Room Measurement Entity

/// Individual measurement entity within a room
@objc(RoomMeasurement)
public class RoomMeasurement: NSManagedObject {
    
    @NSManaged public var id: UUID?
    @NSManaged public var measurementType: String?
    @NSManaged public var value: Float
    @NSManaged public var unit: String?
    @NSManaged public var confidence: Float
    @NSManaged public var timestamp: Date?
    @NSManaged public var notes: String?
    @NSManaged public var startPointData: Data?
    @NSManaged public var endPointData: Data?
    
    // Relationships
    @NSManaged public var room: MultiRoomEntity?
    
    // CloudKit integration
    @NSManaged public var ckRecordID: CKRecord.ID?
    @NSManaged public var ckRecordSystemFields: Data?
}

// MARK: - Room Annotation Entity

/// Annotation entity for room markup and notes
@objc(RoomAnnotation)
public class RoomAnnotation: NSManagedObject {
    
    @NSManaged public var id: UUID?
    @NSManaged public var annotationType: String?
    @NSManaged public var text: String?
    @NSManaged public var timestamp: Date?
    @NSManaged public var authorName: String?
    @NSManaged public var positionData: Data?
    @NSManaged public var colorHex: String?
    @NSManaged public var isResolved: Bool
    
    // Relationships
    @NSManaged public var room: MultiRoomEntity?
    
    // CloudKit integration
    @NSManaged public var ckRecordID: CKRecord.ID?
    @NSManaged public var ckRecordSystemFields: Data?
}

// MARK: - Core Data Model Configuration

extension NSManagedObjectModel {
    
    /// Create the Core Data model programmatically
    static func multiRoomModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        
        // Create entities
        let projectEntity = createProjectEntity()
        let roomEntity = createRoomEntity()
        let transitionEntity = createTransitionEntity()
        let collaboratorEntity = createCollaboratorEntity()
        let measurementEntity = createMeasurementEntity()
        let annotationEntity = createAnnotationEntity()
        
        // Set up relationships
        setupRelationships(
            project: projectEntity,
            room: roomEntity,
            transition: transitionEntity,
            collaborator: collaboratorEntity,
            measurement: measurementEntity,
            annotation: annotationEntity
        )
        
        model.entities = [
            projectEntity,
            roomEntity,
            transitionEntity,
            collaboratorEntity,
            measurementEntity,
            annotationEntity
        ]
        
        return model
    }
    
    private static func createProjectEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "MultiRoomProject"
        entity.managedObjectClassName = "MultiRoomProject"
        
        // Add attributes
        entity.properties = [
            createAttribute(name: "id", type: .UUIDAttributeType),
            createAttribute(name: "name", type: .stringAttributeType),
            createAttribute(name: "projectDescription", type: .stringAttributeType, optional: true),
            createAttribute(name: "createdAt", type: .dateAttributeType),
            createAttribute(name: "updatedAt", type: .dateAttributeType),
            createAttribute(name: "version", type: .integer32AttributeType),
            createAttribute(name: "isCompleted", type: .booleanAttributeType),
            createAttribute(name: "totalFloorArea", type: .floatAttributeType),
            createAttribute(name: "totalVolume", type: .floatAttributeType),
            createAttribute(name: "buildingType", type: .stringAttributeType, optional: true),
            createAttribute(name: "clientName", type: .stringAttributeType, optional: true),
            createAttribute(name: "architectName", type: .stringAttributeType, optional: true),
            createAttribute(name: "projectNotes", type: .stringAttributeType, optional: true)
        ]
        
        return entity
    }
    
    private static func createRoomEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "MultiRoomEntity"
        entity.managedObjectClassName = "MultiRoomEntity"
        
        // Add attributes
        entity.properties = [
            createAttribute(name: "id", type: .UUIDAttributeType),
            createAttribute(name: "roomIndex", type: .integer32AttributeType),
            createAttribute(name: "roomName", type: .stringAttributeType, optional: true),
            createAttribute(name: "roomType", type: .stringAttributeType, optional: true),
            createAttribute(name: "startTime", type: .dateAttributeType, optional: true),
            createAttribute(name: "endTime", type: .dateAttributeType, optional: true),
            createAttribute(name: "isCompleted", type: .booleanAttributeType),
            createAttribute(name: "floorArea", type: .floatAttributeType),
            createAttribute(name: "volume", type: .floatAttributeType),
            createAttribute(name: "ceilingHeight", type: .floatAttributeType),
            createAttribute(name: "perimeter", type: .floatAttributeType),
            createAttribute(name: "usdzFilePath", type: .stringAttributeType, optional: true),
            createAttribute(name: "jsonFilePath", type: .stringAttributeType, optional: true),
            createAttribute(name: "thumbnailImagePath", type: .stringAttributeType, optional: true),
            createAttribute(name: "spatialContextData", type: .binaryDataAttributeType, optional: true),
            createAttribute(name: "qualityMetricsData", type: .binaryDataAttributeType, optional: true),
            createAttribute(name: "roomBoundaryData", type: .binaryDataAttributeType, optional: true)
        ]
        
        return entity
    }
    
    private static func createAttribute(name: String, type: NSAttributeType, optional: Bool = false) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = optional
        return attribute
    }
    
    private static func setupRelationships(
        project: NSEntityDescription,
        room: NSEntityDescription,
        transition: NSEntityDescription,
        collaborator: NSEntityDescription,
        measurement: NSEntityDescription,
        annotation: NSEntityDescription
    ) {
        // Project -> Rooms (one-to-many)
        let projectRoomsRelation = NSRelationshipDescription()
        projectRoomsRelation.name = "rooms"
        projectRoomsRelation.destinationEntity = room
        projectRoomsRelation.minCount = 0
        projectRoomsRelation.maxCount = 0 // unlimited
        projectRoomsRelation.deleteRule = .cascadeDeleteRule
        
        let roomProjectRelation = NSRelationshipDescription()
        roomProjectRelation.name = "project"
        roomProjectRelation.destinationEntity = project
        roomProjectRelation.minCount = 1
        roomProjectRelation.maxCount = 1
        roomProjectRelation.deleteRule = .nullifyDeleteRule
        
        projectRoomsRelation.inverseRelationship = roomProjectRelation
        roomProjectRelation.inverseRelationship = projectRoomsRelation
        
        project.properties.append(projectRoomsRelation)
        room.properties.append(roomProjectRelation)
        
        // Add other relationships similarly...
        // This is a simplified example - full implementation would include all relationships
    }
    
    // Additional helper methods for creating other entities...
    private static func createTransitionEntity() -> NSEntityDescription {
        // Implementation for transition entity
        return NSEntityDescription()
    }
    
    private static func createCollaboratorEntity() -> NSEntityDescription {
        // Implementation for collaborator entity
        return NSEntityDescription()
    }
    
    private static func createMeasurementEntity() -> NSEntityDescription {
        // Implementation for measurement entity
        return NSEntityDescription()
    }
    
    private static func createAnnotationEntity() -> NSEntityDescription {
        // Implementation for annotation entity
        return NSEntityDescription()
    }
}

import Foundation
import UniformTypeIdentifiers
import CoreGraphics
import simd

// MARK: - Export Formats

/// Professional export format definitions
enum ExportFormat: String, CaseIterable, Codable {
    // Standard 3D formats
    case obj = "obj"
    case ply = "ply"
    case stl = "stl"
    case fbx = "fbx"
    case gltf = "gltf"
    case usd = "usd"
    
    // Professional formats
    case ifc4 = "ifc4"
    case e57 = "e57"
    
    // CAD formats
    case autocad = "autocad"
    case rhino = "rhino"
    case revit = "revit"
    case sketchup = "sketchup"
    case blender = "blender"
    
    var displayName: String {
        switch self {
        case .obj: return "Wavefront OBJ"
        case .ply: return "Stanford PLY"
        case .stl: return "STL (Stereolithography)"
        case .fbx: return "Autodesk FBX"
        case .gltf: return "glTF 2.0"
        case .usd: return "Universal Scene Description"
        case .ifc4: return "IFC 4.0 (Building Information)"
        case .e57: return "E57 Point Cloud"
        case .autocad: return "AutoCAD DWG/DXF"
        case .rhino: return "Rhino 3DM"
        case .revit: return "Autodesk Revit"
        case .sketchup: return "SketchUp SKP"
        case .blender: return "Blender"
        }
    }
    
    var fileExtension: String {
        switch self {
        case .obj: return "obj"
        case .ply: return "ply"
        case .stl: return "stl"
        case .fbx: return "fbx"
        case .gltf: return "gltf"
        case .usd: return "usd"
        case .ifc4: return "ifc"
        case .e57: return "e57"
        case .autocad: return "dwg"
        case .rhino: return "3dm"
        case .revit: return "rvt"
        case .sketchup: return "skp"
        case .blender: return "blend"
        }
    }
    
    var mimeType: String {
        switch self {
        case .obj: return "model/obj"
        case .ply: return "model/ply"
        case .stl: return "model/stl"
        case .fbx: return "model/fbx"
        case .gltf: return "model/gltf+json"
        case .usd: return "model/usd"
        case .ifc4: return "model/ifc"
        case .e57: return "model/e57"
        case .autocad: return "application/dwg"
        case .rhino: return "model/3dm"
        case .revit: return "application/rvt"
        case .sketchup: return "model/skp"
        case .blender: return "application/blend"
        }
    }
    
    var supportsPointClouds: Bool {
        switch self {
        case .ply, .e57, .obj: return true
        case .stl, .fbx, .gltf, .usd: return false
        case .ifc4: return true
        case .autocad, .rhino, .revit, .sketchup, .blender: return true
        }
    }
    
    var supportsMeshes: Bool {
        switch self {
        case .obj, .ply, .stl, .fbx, .gltf, .usd: return true
        case .e57: return false
        case .ifc4: return true
        case .autocad, .rhino, .revit, .sketchup, .blender: return true
        }
    }
    
    var supportsTextures: Bool {
        switch self {
        case .obj, .fbx, .gltf, .usd: return true
        case .ply, .stl, .e57: return false
        case .ifc4: return true
        case .autocad, .rhino, .revit, .sketchup, .blender: return true
        }
    }
    
    var supportsAnimation: Bool {
        switch self {
        case .fbx, .gltf, .usd: return true
        case .obj, .ply, .stl, .e57, .ifc4: return false
        case .autocad, .rhino, .revit, .sketchup, .blender: return false
        }
    }
}

// MARK: - Export Data

/// Spatial export data structure
struct SpatialExportData: Identifiable, Codable {
    let id = UUID()
    let sessionId: UUID
    let roomData: RoomExportData
    let pointClouds: [PointCloudExportData]
    let meshes: [MeshExportData]
    let materials: [MaterialExportData]
    let measurements: [MeasurementExportData]
    let metadata: SpatialMetadata
    let timestamp: Date
    
    var estimatedSize: Int64 {
        let pointCloudSize = pointClouds.reduce(0) { $0 + $1.estimatedSize }
        let meshSize = meshes.reduce(0) { $0 + $1.estimatedSize }
        let materialSize = materials.reduce(0) { $0 + $1.estimatedSize }
        return pointCloudSize + meshSize + materialSize + 1024 // Base metadata size
    }
    
    var complexity: DataComplexity {
        let totalPoints = pointClouds.reduce(0) { $0 + $1.pointCount }
        let totalTriangles = meshes.reduce(0) { $0 + $1.triangleCount }
        
        if totalPoints > 1_000_000 || totalTriangles > 500_000 {
            return .veryHigh
        } else if totalPoints > 500_000 || totalTriangles > 250_000 {
            return .high
        } else if totalPoints > 100_000 || totalTriangles > 50_000 {
            return .medium
        } else {
            return .low
        }
    }
}

/// Room export data
struct RoomExportData: Codable {
    let roomId: UUID
    let roomType: String
    let dimensions: RoomDimensions
    let boundingBox: BoundingBox
    let floorPlan: FloorPlanData?
    let surfaces: [SurfaceExportData]
    let objects: [ObjectExportData]
}

/// Point cloud export data
struct PointCloudExportData: Codable {
    let pointCloudId: UUID
    let points: [Point3D]
    let colors: [ColorRGB]?
    let normals: [Vector3D]?
    let intensities: [Float]?
    let classifications: [PointClassification]?
    let confidence: [Float]?
    let timestamp: Date
    
    var pointCount: Int {
        return points.count
    }
    
    var estimatedSize: Int64 {
        let baseSize = pointCount * 12 // 3 floats per point
        let colorSize = (colors?.count ?? 0) * 3 // RGB
        let normalSize = (normals?.count ?? 0) * 12 // 3 floats per normal
        let intensitySize = (intensities?.count ?? 0) * 4 // 1 float per intensity
        return Int64(baseSize + colorSize + normalSize + intensitySize)
    }
}

/// Mesh export data
struct MeshExportData: Codable {
    let meshId: UUID
    let vertices: [Vertex3D]
    let triangles: [Triangle]
    let normals: [Vector3D]?
    let textureCoordinates: [TextureCoordinate]?
    let materials: [String]? // Material references
    let boundingBox: BoundingBox
    let timestamp: Date
    
    var triangleCount: Int {
        return triangles.count
    }
    
    var estimatedSize: Int64 {
        let vertexSize = vertices.count * 12 // 3 floats per vertex
        let triangleSize = triangles.count * 12 // 3 ints per triangle
        let normalSize = (normals?.count ?? 0) * 12 // 3 floats per normal
        let uvSize = (textureCoordinates?.count ?? 0) * 8 // 2 floats per UV
        return Int64(vertexSize + triangleSize + normalSize + uvSize)
    }
}

/// Material export data
struct MaterialExportData: Codable {
    let materialId: UUID
    let name: String
    let type: MaterialType
    let properties: MaterialProperties
    let textures: [TextureData]?
    let pbr: PBRMaterial?
    
    var estimatedSize: Int64 {
        let baseSize: Int64 = 1024 // Base material data
        let textureSize = textures?.reduce(0) { $0 + $1.estimatedSize } ?? 0
        return baseSize + textureSize
    }
}

/// Measurement export data
struct MeasurementExportData: Codable {
    let measurementId: UUID
    let type: MeasurementType
    let value: Float
    let unit: MeasurementUnit
    let startPoint: Point3D
    let endPoint: Point3D?
    let accuracy: Float
    let timestamp: Date
}

// MARK: - Export Options

/// Export options configuration
struct ExportOptions: Codable {
    let quality: ExportQuality
    let enableCompression: Bool
    let compressionLevel: Float // 0.0 - 1.0
    let includeTextures: Bool
    let includeAnimations: Bool
    let includeMetadata: Bool
    let coordinateSystem: CoordinateSystem
    let units: MeasurementUnit
    let precision: ExportPrecision
    let optimizeForSize: Bool
    let optimizeForQuality: Bool
    
    static func `default`() -> ExportOptions {
        return ExportOptions(
            quality: .high,
            enableCompression: true,
            compressionLevel: 0.8,
            includeTextures: true,
            includeAnimations: false,
            includeMetadata: true,
            coordinateSystem: .rightHandedYUp,
            units: .meters,
            precision: .high,
            optimizeForSize: false,
            optimizeForQuality: true
        )
    }
    
    static func professional() -> ExportOptions {
        return ExportOptions(
            quality: .maximum,
            enableCompression: false,
            compressionLevel: 1.0,
            includeTextures: true,
            includeAnimations: true,
            includeMetadata: true,
            coordinateSystem: .rightHandedYUp,
            units: .meters,
            precision: .maximum,
            optimizeForSize: false,
            optimizeForQuality: true
        )
    }
}

/// Export quality levels
enum ExportQuality: String, CaseIterable, Codable {
    case draft = "draft"
    case standard = "standard"
    case high = "high"
    case maximum = "maximum"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var qualityMultiplier: Float {
        switch self {
        case .draft: return 0.5
        case .standard: return 0.75
        case .high: return 0.9
        case .maximum: return 1.0
        }
    }
}

/// Export precision levels
enum ExportPrecision: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case maximum = "maximum"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var decimalPlaces: Int {
        switch self {
        case .low: return 2
        case .medium: return 4
        case .high: return 6
        case .maximum: return 8
        }
    }
}

/// Coordinate system definitions
enum CoordinateSystem: String, CaseIterable, Codable {
    case rightHandedYUp = "right_handed_y_up"
    case rightHandedZUp = "right_handed_z_up"
    case leftHandedYUp = "left_handed_y_up"
    case leftHandedZUp = "left_handed_z_up"
    
    var displayName: String {
        switch self {
        case .rightHandedYUp: return "Right-Handed Y-Up"
        case .rightHandedZUp: return "Right-Handed Z-Up"
        case .leftHandedYUp: return "Left-Handed Y-Up"
        case .leftHandedZUp: return "Left-Handed Z-Up"
        }
    }
}

// MARK: - Export Results

/// Export result
enum ExportResult {
    case success(data: FinalExportData, format: ExportFormat, metadata: ExportMetadata)
    case failure(error: ExportError)
    
    var isSuccess: Bool {
        switch self {
        case .success: return true
        case .failure: return false
        }
    }
    
    var exportData: FinalExportData? {
        switch self {
        case .success(let data, _, _): return data
        case .failure: return nil
        }
    }
    
    var error: ExportError? {
        switch self {
        case .success: return nil
        case .failure(let error): return error
        }
    }
}

/// Export errors
enum ExportError: Error, LocalizedError {
    case exportInProgress
    case validationFailed([ValidationError])
    case processingError(Error)
    case qualityThresholdNotMet(Float)
    case outputValidationFailed([ValidationError])
    case unsupportedFormat(ExportFormat)
    case fileSizeExceeded(Int64)
    case compressionFailed
    case metadataEmbeddingFailed
    
    var errorDescription: String? {
        switch self {
        case .exportInProgress:
            return "Export already in progress"
        case .validationFailed(let errors):
            return "Validation failed: \(errors.map { $0.localizedDescription }.joined(separator: ", "))"
        case .processingError(let error):
            return "Processing error: \(error.localizedDescription)"
        case .qualityThresholdNotMet(let score):
            return "Quality threshold not met: \(score)"
        case .outputValidationFailed(let errors):
            return "Output validation failed: \(errors.map { $0.localizedDescription }.joined(separator: ", "))"
        case .unsupportedFormat(let format):
            return "Unsupported format: \(format.displayName)"
        case .fileSizeExceeded(let size):
            return "File size exceeded: \(size) bytes"
        case .compressionFailed:
            return "Compression failed"
        case .metadataEmbeddingFailed:
            return "Metadata embedding failed"
        }
    }
}

/// Export metadata
struct ExportMetadata: Codable {
    let exportId: UUID
    let format: ExportFormat
    let quality: Float
    let fileSize: Int
    let processingTime: TimeInterval
    let timestamp: Date
    let version: String = "1.0"
    let generator: String = "ScanPlan Professional"
}

// MARK: - Export Progress

/// Export progress tracking
struct ExportProgress: Codable {
    let taskId: UUID?
    let stage: ExportStage
    let percentage: Float // 0.0 - 1.0
    let currentOperation: String?
    let estimatedTimeRemaining: TimeInterval?
    let timestamp: Date
    
    init() {
        self.taskId = nil
        self.stage = .idle
        self.percentage = 0.0
        self.currentOperation = nil
        self.estimatedTimeRemaining = nil
        self.timestamp = Date()
    }
    
    init(taskId: UUID, stage: ExportStage, percentage: Float = 0.0, operation: String? = nil) {
        self.taskId = taskId
        self.stage = stage
        self.percentage = percentage
        self.currentOperation = operation
        self.estimatedTimeRemaining = nil
        self.timestamp = Date()
    }
}

/// Export stages
enum ExportStage: String, CaseIterable, Codable {
    case idle = "idle"
    case preparing = "preparing"
    case validating = "validating"
    case processing = "processing"
    case compressing = "compressing"
    case embedding = "embedding"
    case finalizing = "finalizing"
    case completed = "completed"
    case failed = "failed"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var icon: String {
        switch self {
        case .idle: return "circle"
        case .preparing: return "gear"
        case .validating: return "checkmark.shield"
        case .processing: return "cpu"
        case .compressing: return "archivebox"
        case .embedding: return "doc.badge.plus"
        case .finalizing: return "checkmark.circle"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        }
    }
}

// MARK: - Export History

/// Export record for history tracking
struct ExportRecord: Identifiable, Codable {
    let id: UUID
    let format: ExportFormat
    let result: ExportResult
    let timestamp: Date
    let processingTime: TimeInterval
    let dataSize: Int64
    
    var isSuccessful: Bool {
        return result.isSuccess
    }
    
    var displayName: String {
        return "\(format.displayName) - \(timestamp.formatted())"
    }
}

/// Export metrics
struct ExportMetrics: Codable {
    var totalExports: Int = 0
    var successfulExports: Int = 0
    var failedExports: Int = 0
    var totalProcessingTime: TimeInterval = 0.0
    var totalDataExported: Int64 = 0
    var averageProcessingTime: TimeInterval = 0.0
    var successRate: Float = 0.0
    var activeExports: Int = 0
    var lastUpdate: Date = Date()
    
    var efficiency: Float {
        guard totalProcessingTime > 0 else { return 0.0 }
        return Float(totalDataExported) / Float(totalProcessingTime) / 1_000_000.0 // MB/s
    }
}

// MARK: - Professional Workflows

/// Professional workflow types
enum ProfessionalWorkflow: String, CaseIterable, Codable {
    case architecture = "architecture"
    case engineering = "engineering"
    case construction = "construction"
    case manufacturing = "manufacturing"
    case gaming = "gaming"
    case vfx = "vfx"
    case research = "research"
    case preservation = "preservation"
    
    var displayName: String {
        switch self {
        case .architecture: return "Architecture & Design"
        case .engineering: return "Engineering"
        case .construction: return "Construction"
        case .manufacturing: return "Manufacturing"
        case .gaming: return "Game Development"
        case .vfx: return "Visual Effects"
        case .research: return "Research & Academia"
        case .preservation: return "Cultural Preservation"
        }
    }
    
    var preferredFormats: [ExportFormat] {
        switch self {
        case .architecture:
            return [.ifc4, .revit, .autocad, .rhino]
        case .engineering:
            return [.autocad, .rhino, .stl, .obj]
        case .construction:
            return [.ifc4, .revit, .autocad, .e57]
        case .manufacturing:
            return [.stl, .obj, .ply, .autocad]
        case .gaming:
            return [.fbx, .gltf, .obj, .blender]
        case .vfx:
            return [.fbx, .usd, .obj, .blender]
        case .research:
            return [.ply, .e57, .obj, .usd]
        case .preservation:
            return [.e57, .ply, .obj, .ifc4]
        }
    }
}

// MARK: - Export Capabilities

/// Export capabilities for each format
struct ExportCapabilities: Codable {
    let format: ExportFormat
    let supportsPointClouds: Bool
    let supportsMeshes: Bool
    let supportsTextures: Bool
    let supportsAnimation: Bool
    let supportsMaterials: Bool
    let supportsMetadata: Bool
    let maxFileSize: Int64?
    let supportedPrecisions: [ExportPrecision]
    let supportedCoordinateSystems: [CoordinateSystem]
    let compressionSupport: CompressionSupport

    static func `default`(for format: ExportFormat) -> ExportCapabilities {
        return ExportCapabilities(
            format: format,
            supportsPointClouds: format.supportsPointClouds,
            supportsMeshes: format.supportsMeshes,
            supportsTextures: format.supportsTextures,
            supportsAnimation: format.supportsAnimation,
            supportsMaterials: true,
            supportsMetadata: true,
            maxFileSize: 2_000_000_000, // 2GB
            supportedPrecisions: ExportPrecision.allCases,
            supportedCoordinateSystems: CoordinateSystem.allCases,
            compressionSupport: .optional
        )
    }
}

/// Compression support levels
enum CompressionSupport: String, CaseIterable, Codable {
    case none = "none"
    case optional = "optional"
    case required = "required"
    case automatic = "automatic"

    var displayName: String {
        return rawValue.capitalized
    }
}

// MARK: - Validation

/// Validation result
struct ValidationResult: Codable {
    let isValid: Bool
    let errors: [ValidationError]
    let warnings: [ValidationWarning]
    let score: Float // 0.0 - 1.0

    static func valid() -> ValidationResult {
        return ValidationResult(isValid: true, errors: [], warnings: [], score: 1.0)
    }

    static func invalid(errors: [ValidationError]) -> ValidationResult {
        return ValidationResult(isValid: false, errors: errors, warnings: [], score: 0.0)
    }
}

/// Validation error
struct ValidationError: Error, LocalizedError, Codable {
    let code: String
    let message: String
    let severity: ValidationSeverity

    var errorDescription: String? {
        return message
    }
}

/// Validation warning
struct ValidationWarning: Codable {
    let code: String
    let message: String
    let suggestion: String?
}

/// Validation severity
enum ValidationSeverity: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"

    var displayName: String {
        return rawValue.capitalized
    }
}

// MARK: - Export Recommendations

/// Export recommendation
struct ExportRecommendation: Identifiable, Codable {
    let id = UUID()
    let format: ExportFormat
    let workflow: ProfessionalWorkflow
    let score: Float // 0.0 - 1.0
    let reasons: [String]
    let optimizations: [ExportOptimization]

    var displayName: String {
        return "\(format.displayName) for \(workflow.displayName)"
    }
}

/// Export optimization
struct ExportOptimization: Codable {
    let type: OptimizationType
    let description: String
    let impact: OptimizationImpact
    let parameters: [String: Any]

    enum CodingKeys: String, CodingKey {
        case type, description, impact
    }

    init(type: OptimizationType, description: String, impact: OptimizationImpact, parameters: [String: Any] = [:]) {
        self.type = type
        self.description = description
        self.impact = impact
        self.parameters = parameters
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(OptimizationType.self, forKey: .type)
        description = try container.decode(String.self, forKey: .description)
        impact = try container.decode(OptimizationImpact.self, forKey: .impact)
        parameters = [:]
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(description, forKey: .description)
        try container.encode(impact, forKey: .impact)
    }
}

/// Optimization types
enum OptimizationType: String, CaseIterable, Codable {
    case compression = "compression"
    case decimation = "decimation"
    case uvMapping = "uv_mapping"
    case materialOptimization = "material_optimization"
    case coordinateTransform = "coordinate_transform"
    case precisionAdjustment = "precision_adjustment"

    var displayName: String {
        return rawValue.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

/// Optimization impact
enum OptimizationImpact: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"

    var displayName: String {
        return rawValue.capitalized
    }
}

// MARK: - Data Complexity

/// Data complexity levels
enum DataComplexity: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case veryHigh = "very_high"

    var displayName: String {
        return rawValue.replacingOccurrences(of: "_", with: " ").capitalized
    }

    var processingMultiplier: Float {
        switch self {
        case .low: return 1.0
        case .medium: return 2.0
        case .high: return 4.0
        case .veryHigh: return 8.0
        }
    }
}

// MARK: - Geometric Data Types

/// 3D point
struct Point3D: Codable {
    let x: Float
    let y: Float
    let z: Float

    init(_ x: Float, _ y: Float, _ z: Float) {
        self.x = x
        self.y = y
        self.z = z
    }
}

/// 3D vector
struct Vector3D: Codable {
    let x: Float
    let y: Float
    let z: Float

    init(_ x: Float, _ y: Float, _ z: Float) {
        self.x = x
        self.y = y
        self.z = z
    }
}

/// RGB color
struct ColorRGB: Codable {
    let r: UInt8
    let g: UInt8
    let b: UInt8

    init(_ r: UInt8, _ g: UInt8, _ b: UInt8) {
        self.r = r
        self.g = g
        self.b = b
    }
}

/// 3D vertex
struct Vertex3D: Codable {
    let position: Point3D
    let normal: Vector3D?
    let textureCoordinate: TextureCoordinate?
    let color: ColorRGB?
}

/// Triangle
struct Triangle: Codable {
    let v1: Int
    let v2: Int
    let v3: Int

    init(_ v1: Int, _ v2: Int, _ v3: Int) {
        self.v1 = v1
        self.v2 = v2
        self.v3 = v3
    }
}

/// Texture coordinate
struct TextureCoordinate: Codable {
    let u: Float
    let v: Float

    init(_ u: Float, _ v: Float) {
        self.u = u
        self.v = v
    }
}

/// Bounding box
struct BoundingBox: Codable {
    let min: Point3D
    let max: Point3D

    var center: Point3D {
        return Point3D(
            (min.x + max.x) / 2,
            (min.y + max.y) / 2,
            (min.z + max.z) / 2
        )
    }

    var size: Vector3D {
        return Vector3D(
            max.x - min.x,
            max.y - min.y,
            max.z - min.z
        )
    }
}

// MARK: - Material Data

/// Material type
enum MaterialType: String, CaseIterable, Codable {
    case diffuse = "diffuse"
    case pbr = "pbr"
    case phong = "phong"
    case lambert = "lambert"
    case unlit = "unlit"

    var displayName: String {
        switch self {
        case .diffuse: return "Diffuse"
        case .pbr: return "PBR (Physically Based)"
        case .phong: return "Phong"
        case .lambert: return "Lambert"
        case .unlit: return "Unlit"
        }
    }
}

/// Material properties
struct MaterialProperties: Codable {
    let diffuseColor: ColorRGB
    let specularColor: ColorRGB?
    let emissiveColor: ColorRGB?
    let shininess: Float?
    let transparency: Float?
    let reflectivity: Float?
}

/// PBR material
struct PBRMaterial: Codable {
    let baseColor: ColorRGB
    let metallic: Float
    let roughness: Float
    let normal: Float?
    let occlusion: Float?
    let emission: ColorRGB?
}

/// Texture data
struct TextureData: Codable {
    let textureId: UUID
    let type: TextureType
    let width: Int
    let height: Int
    let format: TextureFormat
    let data: Data

    var estimatedSize: Int64 {
        return Int64(data.count)
    }
}

/// Texture type
enum TextureType: String, CaseIterable, Codable {
    case diffuse = "diffuse"
    case normal = "normal"
    case specular = "specular"
    case roughness = "roughness"
    case metallic = "metallic"
    case occlusion = "occlusion"
    case emission = "emission"

    var displayName: String {
        return rawValue.capitalized
    }
}

/// Texture format
enum TextureFormat: String, CaseIterable, Codable {
    case png = "png"
    case jpeg = "jpeg"
    case tiff = "tiff"
    case exr = "exr"
    case hdr = "hdr"

    var displayName: String {
        return rawValue.uppercased()
    }
}

// MARK: - Measurement Data

/// Measurement type
enum MeasurementType: String, CaseIterable, Codable {
    case distance = "distance"
    case area = "area"
    case volume = "volume"
    case angle = "angle"
    case height = "height"
    case width = "width"
    case depth = "depth"

    var displayName: String {
        return rawValue.capitalized
    }
}

/// Measurement unit
enum MeasurementUnit: String, CaseIterable, Codable {
    case millimeters = "mm"
    case centimeters = "cm"
    case meters = "m"
    case inches = "in"
    case feet = "ft"
    case yards = "yd"

    var displayName: String {
        switch self {
        case .millimeters: return "Millimeters"
        case .centimeters: return "Centimeters"
        case .meters: return "Meters"
        case .inches: return "Inches"
        case .feet: return "Feet"
        case .yards: return "Yards"
        }
    }

    var symbol: String {
        return rawValue
    }
}

// MARK: - Point Classification

/// Point classification for point clouds
enum PointClassification: String, CaseIterable, Codable {
    case unclassified = "unclassified"
    case ground = "ground"
    case lowVegetation = "low_vegetation"
    case mediumVegetation = "medium_vegetation"
    case highVegetation = "high_vegetation"
    case building = "building"
    case lowPoint = "low_point"
    case water = "water"
    case rail = "rail"
    case roadSurface = "road_surface"
    case wireGuard = "wire_guard"
    case wireConductor = "wire_conductor"
    case transmissionTower = "transmission_tower"
    case wireStructureConnector = "wire_structure_connector"
    case bridgeDeck = "bridge_deck"
    case highNoise = "high_noise"

    var displayName: String {
        return rawValue.replacingOccurrences(of: "_", with: " ").capitalized
    }

    var color: ColorRGB {
        switch self {
        case .unclassified: return ColorRGB(128, 128, 128)
        case .ground: return ColorRGB(139, 69, 19)
        case .lowVegetation: return ColorRGB(0, 255, 0)
        case .mediumVegetation: return ColorRGB(0, 200, 0)
        case .highVegetation: return ColorRGB(0, 150, 0)
        case .building: return ColorRGB(255, 0, 0)
        case .lowPoint: return ColorRGB(255, 255, 0)
        case .water: return ColorRGB(0, 0, 255)
        case .rail: return ColorRGB(255, 165, 0)
        case .roadSurface: return ColorRGB(64, 64, 64)
        case .wireGuard: return ColorRGB(255, 0, 255)
        case .wireConductor: return ColorRGB(255, 192, 203)
        case .transmissionTower: return ColorRGB(128, 0, 128)
        case .wireStructureConnector: return ColorRGB(255, 20, 147)
        case .bridgeDeck: return ColorRGB(165, 42, 42)
        case .highNoise: return ColorRGB(255, 255, 255)
        }
    }
}

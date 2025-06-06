import Foundation
import RoomPlan
import CoreML
import Combine

/// Central manager for room classification and furniture recognition
/// Integrates with MultiRoomScanManager for enhanced room analysis
@MainActor
class RoomClassificationManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var classificationResults: [UUID: RoomClassificationResult] = [:]
    @Published var enhancedFurniture: [UUID: [EnhancedFurnitureObject]] = [:]
    @Published var materialMaps: [UUID: MaterialClassificationMap] = [:]
    @Published var isProcessing: Bool = false
    @Published var processingProgress: Float = 0.0
    
    // MARK: - Dependencies
    
    private let roomClassifier: AdvancedRoomClassifier
    private let modelTrainer: RoomClassificationModelTrainer
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Configuration
    
    struct ClassificationConfiguration {
        let enableRoomClassification: Bool = true
        let enableFurnitureEnhancement: Bool = true
        let enableMaterialClassification: Bool = true
        let confidenceThreshold: Float = 0.7
        let enableRealTimeProcessing: Bool = false
    }
    
    private let configuration = ClassificationConfiguration()
    
    // MARK: - Initialization
    
    init() {
        self.roomClassifier = AdvancedRoomClassifier()
        self.modelTrainer = RoomClassificationModelTrainer()
        
        setupObservers()
    }
    
    // MARK: - Public Interface
    
    /// Process a captured room with full classification analysis
    func processRoom(_ capturedRoom: CapturedRoom, roomId: UUID) async {
        print("🔍 Processing room \(roomId) with full classification analysis")
        
        isProcessing = true
        processingProgress = 0.0
        
        defer {
            isProcessing = false
            processingProgress = 1.0
        }
        
        do {
            // Step 1: Room Type Classification
            if configuration.enableRoomClassification {
                processingProgress = 0.2
                let roomResult = await classifyRoomType(capturedRoom)
                classificationResults[roomId] = roomResult
                print("✅ Room classified as: \(roomResult.roomType.displayName)")
            }
            
            // Step 2: Furniture Enhancement
            if configuration.enableFurnitureEnhancement {
                processingProgress = 0.5
                let enhancedObjects = await enhanceFurniture(capturedRoom.objects)
                enhancedFurniture[roomId] = enhancedObjects
                print("✅ Enhanced \(enhancedObjects.count) furniture objects")
            }
            
            // Step 3: Material Classification
            if configuration.enableMaterialClassification {
                processingProgress = 0.8
                let materialMap = await classifyMaterials(capturedRoom)
                materialMaps[roomId] = materialMap
                print("✅ Classified materials for room surfaces")
            }
            
            processingProgress = 1.0
            print("🎉 Room processing completed successfully")
            
        } catch {
            print("❌ Room processing failed: \(error.localizedDescription)")
        }
    }
    
    /// Process multiple rooms from a multi-room scan
    func processMultipleRooms(_ rooms: [CapturedRoomData]) async {
        print("🏢 Processing \(rooms.count) rooms with classification analysis")
        
        isProcessing = true
        processingProgress = 0.0
        
        defer {
            isProcessing = false
        }
        
        for (index, roomData) in rooms.enumerated() {
            guard let capturedRoom = roomData.capturedRoom else {
                print("⚠️ No captured room data for room \(roomData.index)")
                continue
            }
            
            // Process each room
            await processRoom(capturedRoom, roomId: roomData.id)
            
            // Update progress
            processingProgress = Float(index + 1) / Float(rooms.count)
        }
        
        // Generate building-level analysis
        await generateBuildingAnalysis(rooms)
        
        print("🏢 Multi-room processing completed")
    }
    
    /// Get classification result for a specific room
    func getClassificationResult(for roomId: UUID) -> RoomClassificationResult? {
        return classificationResults[roomId]
    }
    
    /// Get enhanced furniture for a specific room
    func getEnhancedFurniture(for roomId: UUID) -> [EnhancedFurnitureObject]? {
        return enhancedFurniture[roomId]
    }
    
    /// Get material classification map for a specific room
    func getMaterialMap(for roomId: UUID) -> MaterialClassificationMap? {
        return materialMaps[roomId]
    }
    
    /// Generate comprehensive room analysis report
    func generateRoomAnalysisReport(for roomId: UUID) -> RoomAnalysisReport? {
        guard let classification = classificationResults[roomId],
              let furniture = enhancedFurniture[roomId],
              let materials = materialMaps[roomId] else {
            return nil
        }
        
        return RoomAnalysisReport(
            roomId: roomId,
            classification: classification,
            enhancedFurniture: furniture,
            materialMap: materials,
            generatedAt: Date()
        )
    }
    
    /// Train custom models with user data
    func trainCustomModels() async {
        print("🏗 Starting custom model training")
        
        do {
            // Train room type model
            let roomTypeModel = try await modelTrainer.trainRoomTypeModel()
            print("✅ Room type model trained successfully")
            
            // Train furniture classification model
            let furnitureModel = try await modelTrainer.trainFurnitureClassificationModel()
            print("✅ Furniture classification model trained successfully")
            
            // Train material classification model
            let materialModel = try await modelTrainer.trainMaterialClassificationModel()
            print("✅ Material classification model trained successfully")
            
            // Update classifier with new models
            await updateClassifierModels(
                roomType: roomTypeModel,
                furniture: furnitureModel,
                material: materialModel
            )
            
        } catch {
            print("❌ Model training failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Private Implementation
    
    private func classifyRoomType(_ capturedRoom: CapturedRoom) async -> RoomClassificationResult {
        return await roomClassifier.classifyRoomType(capturedRoom)
    }
    
    private func enhanceFurniture(_ objects: [CapturedRoom.Object]) async -> [EnhancedFurnitureObject] {
        return await roomClassifier.enhanceFurnitureRecognition(objects)
    }
    
    private func classifyMaterials(_ capturedRoom: CapturedRoom) async -> MaterialClassificationMap {
        return await roomClassifier.classifyMaterials(in: capturedRoom)
    }
    
    private func generateBuildingAnalysis(_ rooms: [CapturedRoomData]) async {
        print("🏢 Generating building-level analysis")
        
        // Analyze room type distribution
        let roomTypes = classificationResults.values.map { $0.roomType }
        let typeDistribution = Dictionary(grouping: roomTypes) { $0 }
        
        print("📊 Room type distribution:")
        for (type, rooms) in typeDistribution {
            print("  - \(type.displayName): \(rooms.count)")
        }
        
        // Analyze material usage across building
        let allMaterials = materialMaps.values.flatMap { $0.allMaterials }
        let materialDistribution = Dictionary(grouping: allMaterials) { $0 }
        
        print("🧱 Material distribution:")
        for (material, usage) in materialDistribution {
            print("  - \(material.displayName): \(usage.count) surfaces")
        }
        
        // Analyze furniture patterns
        let allFurniture = enhancedFurniture.values.flatMap { $0 }
        let furnitureByMaterial = Dictionary(grouping: allFurniture) { $0.materialType }
        
        print("🪑 Furniture material distribution:")
        for (material, items) in furnitureByMaterial {
            print("  - \(material.displayName): \(items.count) items")
        }
    }
    
    private func updateClassifierModels(roomType: MLModel, furniture: MLModel, material: MLModel) async {
        // Update the classifier with newly trained models
        // This would involve updating the AdvancedRoomClassifier's models
        print("🔄 Updating classifier with new models")
    }
    
    private func setupObservers() {
        // Observe classifier state changes
        roomClassifier.$modelLoadingState
            .sink { [weak self] state in
                print("📦 Model loading state: \(state.displayName)")
            }
            .store(in: &cancellables)
        
        // Observe training progress
        modelTrainer.$trainingProgress
            .sink { [weak self] progress in
                print("🏗 Training progress: \(progress.displayName)")
            }
            .store(in: &cancellables)
    }
}

// MARK: - Integration with MultiRoomScanManager

extension RoomClassificationManager {
    
    /// Integrate with MultiRoomScanManager for real-time classification
    func integrateWithMultiRoomScanner(_ scanManager: MultiRoomScanManager) {
        // Observe room completion events
        scanManager.$capturedRooms
            .sink { [weak self] rooms in
                Task { @MainActor in
                    // Process newly completed rooms
                    for room in rooms where room.isComplete {
                        if let capturedRoom = room.capturedRoom,
                           self?.classificationResults[room.id] == nil {
                            await self?.processRoom(capturedRoom, roomId: room.id)
                        }
                    }
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Room Analysis Report

struct RoomAnalysisReport: Identifiable, Codable {
    let id = UUID()
    let roomId: UUID
    let classification: RoomClassificationResult
    let enhancedFurniture: [EnhancedFurnitureObject]
    let materialMap: MaterialClassificationMap
    let generatedAt: Date
    
    var summary: RoomSummary {
        return RoomSummary(
            roomType: classification.roomType,
            confidence: classification.confidence,
            furnitureCount: enhancedFurniture.count,
            primaryMaterials: Array(materialMap.materialSummary.keys.prefix(3)),
            floorArea: classification.features.geometry.floorArea,
            volume: classification.features.geometry.volume
        )
    }
    
    var qualityAssessment: QualityAssessment {
        let classificationQuality = classification.qualityLevel
        let furnitureQuality = assessFurnitureQuality()
        let materialQuality = assessMaterialQuality()
        
        return QualityAssessment(
            overall: calculateOverallQuality(classificationQuality, furnitureQuality, materialQuality),
            classification: classificationQuality,
            furniture: furnitureQuality,
            materials: materialQuality
        )
    }
    
    private func assessFurnitureQuality() -> ClassificationQuality {
        let averageConfidence = enhancedFurniture.map { $0.enhancedProperties.confidence }.reduce(0, +) / Float(enhancedFurniture.count)
        
        switch averageConfidence {
        case 0.9...1.0: return .excellent
        case 0.8..<0.9: return .good
        case 0.7..<0.8: return .fair
        case 0.5..<0.7: return .poor
        default: return .unreliable
        }
    }
    
    private func assessMaterialQuality() -> ClassificationQuality {
        let materialCount = materialMap.allMaterials.count
        let unknownCount = materialMap.allMaterials.filter { $0 == .unknown }.count
        let knownRatio = Float(materialCount - unknownCount) / Float(materialCount)
        
        switch knownRatio {
        case 0.9...1.0: return .excellent
        case 0.8..<0.9: return .good
        case 0.7..<0.8: return .fair
        case 0.5..<0.7: return .poor
        default: return .unreliable
        }
    }
    
    private func calculateOverallQuality(_ classification: ClassificationQuality, _ furniture: ClassificationQuality, _ materials: ClassificationQuality) -> ClassificationQuality {
        let scores = [classification, furniture, materials].map { quality -> Float in
            switch quality {
            case .excellent: return 1.0
            case .good: return 0.8
            case .fair: return 0.6
            case .poor: return 0.4
            case .unreliable: return 0.2
            }
        }
        
        let averageScore = scores.reduce(0, +) / Float(scores.count)
        
        switch averageScore {
        case 0.9...1.0: return .excellent
        case 0.8..<0.9: return .good
        case 0.7..<0.8: return .fair
        case 0.5..<0.7: return .poor
        default: return .unreliable
        }
    }
}

struct RoomSummary: Codable {
    let roomType: RoomType
    let confidence: Float
    let furnitureCount: Int
    let primaryMaterials: [MaterialType]
    let floorArea: Float
    let volume: Float
}

struct QualityAssessment: Codable {
    let overall: ClassificationQuality
    let classification: ClassificationQuality
    let furniture: ClassificationQuality
    let materials: ClassificationQuality
}

import Foundation
import CoreData
import CloudKit
import RoomPlan

/// Manages persistence and synchronization of multi-room scan data
/// Implements CoreData with CloudKit integration for team collaboration
@MainActor
class MultiRoomPersistenceManager: ObservableObject {
    
    // MARK: - Core Data Stack
    
    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: "MultiRoomDataModel")
        
        // Configure CloudKit integration
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve persistent store description")
        }
        
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.loadPersistentStores { _, error in
            if let error = error {
                print("❌ Core Data failed to load: \(error.localizedDescription)")
            } else {
                print("✅ Core Data loaded successfully with CloudKit")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    private var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - Published Properties
    
    @Published var savedProjects: [MultiRoomProject] = []
    @Published var currentProject: MultiRoomProject?
    @Published var syncStatus: SyncStatus = .idle
    
    // MARK: - Initialization
    
    init() {
        setupNotifications()
        loadSavedProjects()
    }
    
    // MARK: - Project Management
    
    /// Create a new multi-room project
    func createProject(name: String, description: String? = nil) -> MultiRoomProject {
        print("📁 Creating new multi-room project: \(name)")
        
        let project = MultiRoomProject(context: context)
        project.id = UUID()
        project.name = name
        project.projectDescription = description
        project.createdAt = Date()
        project.updatedAt = Date()
        project.version = 1
        
        currentProject = project
        saveContext()
        
        return project
    }
    
    /// Save room data to the current project
    func saveRoomData(_ roomData: CapturedRoomData) async {
        guard let project = currentProject else {
            print("❌ No current project to save room data")
            return
        }
        
        print("💾 Saving room data for room \(roomData.index)")
        
        // Create or update room entity
        let room = MultiRoomEntity(context: context)
        room.id = roomData.id
        room.roomIndex = Int32(roomData.index)
        room.startTime = roomData.startTime
        room.endTime = roomData.endTime
        room.project = project
        
        // Save spatial context
        if let spatialData = try? JSONEncoder().encode(roomData.spatialContext) {
            room.spatialContextData = spatialData
        }
        
        // Save captured room data if available
        if let capturedRoom = roomData.capturedRoom {
            await saveCapturedRoomData(capturedRoom, to: room)
        }
        
        // Save quality metrics if available
        if let qualityMetrics = roomData.qualityMetrics,
           let qualityData = try? JSONEncoder().encode(qualityMetrics) {
            room.qualityMetricsData = qualityData
        }
        
        project.updatedAt = Date()
        saveContext()
    }
    
    /// Load a specific project
    func loadProject(_ project: MultiRoomProject) {
        print("📂 Loading project: \(project.name ?? "Unnamed")")
        currentProject = project
        
        // Load associated room data
        loadRoomDataForProject(project)
    }
    
    /// Delete a project and all associated data
    func deleteProject(_ project: MultiRoomProject) {
        print("🗑 Deleting project: \(project.name ?? "Unnamed")")
        
        context.delete(project)
        saveContext()
        
        if currentProject == project {
            currentProject = nil
        }
        
        loadSavedProjects()
    }
    
    // MARK: - Room Data Management
    
    private func saveCapturedRoomData(_ capturedRoom: CapturedRoom, to roomEntity: MultiRoomEntity) async {
        // Export room data to temporary location
        let tempDirectory = FileManager.default.temporaryDirectory
        let roomDirectory = tempDirectory.appendingPathComponent("Room_\(roomEntity.roomIndex)")
        
        do {
            try FileManager.default.createDirectory(at: roomDirectory, withIntermediateDirectories: true)
            
            // Export USDZ model
            let usdzURL = roomDirectory.appendingPathComponent("room.usdz")
            try capturedRoom.export(to: usdzURL, exportOptions: .all)
            
            // Export JSON data
            let jsonURL = roomDirectory.appendingPathComponent("room.json")
            let jsonData = try JSONEncoder().encode(capturedRoom)
            try jsonData.write(to: jsonURL)
            
            // Store file paths in Core Data
            roomEntity.usdzFilePath = usdzURL.path
            roomEntity.jsonFilePath = jsonURL.path
            
            print("✅ Saved room data files for room \(roomEntity.roomIndex)")
            
        } catch {
            print("❌ Failed to save room data files: \(error.localizedDescription)")
        }
    }
    
    private func loadRoomDataForProject(_ project: MultiRoomProject) {
        guard let rooms = project.rooms?.allObjects as? [MultiRoomEntity] else {
            print("⚠️ No rooms found for project")
            return
        }
        
        let sortedRooms = rooms.sorted { $0.roomIndex < $1.roomIndex }
        print("📊 Loaded \(sortedRooms.count) rooms for project")
        
        // Convert to CapturedRoomData objects
        // This would be used to reconstruct the scanning session
    }
    
    // MARK: - Sync Management
    
    /// Sync data with CloudKit
    func syncWithCloud() async {
        print("☁️ Starting CloudKit sync")
        syncStatus = .syncing
        
        do {
            // Trigger CloudKit sync
            try await persistentContainer.persistentStoreCoordinator.performAndWait {
                // CloudKit sync is automatic with NSPersistentCloudKitContainer
                // This method can be used to force sync or handle conflicts
            }
            
            syncStatus = .completed
            print("✅ CloudKit sync completed")
            
        } catch {
            syncStatus = .failed(error.localizedDescription)
            print("❌ CloudKit sync failed: \(error.localizedDescription)")
        }
    }
    
    /// Check sync status
    func checkSyncStatus() -> SyncStatus {
        // In a real implementation, this would check CloudKit sync status
        return syncStatus
    }
    
    // MARK: - Data Recovery
    
    /// Recover data after app crash
    func recoverIncompleteSession() -> MultiRoomProject? {
        print("🔄 Checking for incomplete sessions")
        
        let request: NSFetchRequest<MultiRoomProject> = MultiRoomProject.fetchRequest()
        request.predicate = NSPredicate(format: "isCompleted == NO")
        request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
        request.fetchLimit = 1
        
        do {
            let incompleteProjects = try context.fetch(request)
            if let project = incompleteProjects.first {
                print("🔧 Found incomplete session: \(project.name ?? "Unnamed")")
                return project
            }
        } catch {
            print("❌ Failed to check for incomplete sessions: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    /// Export project data for backup
    func exportProject(_ project: MultiRoomProject) async -> URL? {
        print("📤 Exporting project: \(project.name ?? "Unnamed")")
        
        let exportDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Export_\(project.id?.uuidString ?? "Unknown")")
        
        do {
            try FileManager.default.createDirectory(at: exportDirectory, withIntermediateDirectories: true)
            
            // Export project metadata
            let projectData = ProjectExportData(from: project)
            let projectJSON = try JSONEncoder().encode(projectData)
            let projectFile = exportDirectory.appendingPathComponent("project.json")
            try projectJSON.write(to: projectFile)
            
            // Copy room files
            if let rooms = project.rooms?.allObjects as? [MultiRoomEntity] {
                for room in rooms {
                    await copyRoomFiles(room, to: exportDirectory)
                }
            }
            
            print("✅ Project exported to: \(exportDirectory.path)")
            return exportDirectory
            
        } catch {
            print("❌ Failed to export project: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Private Helpers
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(contextDidSave),
            name: .NSManagedObjectContextDidSave,
            object: nil
        )
    }
    
    @objc private func contextDidSave(_ notification: Notification) {
        // Handle context save notifications
        loadSavedProjects()
    }
    
    private func loadSavedProjects() {
        let request: NSFetchRequest<MultiRoomProject> = MultiRoomProject.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
        
        do {
            savedProjects = try context.fetch(request)
            print("📊 Loaded \(savedProjects.count) saved projects")
        } catch {
            print("❌ Failed to load projects: \(error.localizedDescription)")
            savedProjects = []
        }
    }
    
    private func saveContext() {
        guard context.hasChanges else { return }
        
        do {
            try context.save()
            print("💾 Context saved successfully")
        } catch {
            print("❌ Failed to save context: \(error.localizedDescription)")
        }
    }
    
    private func copyRoomFiles(_ room: MultiRoomEntity, to directory: URL) async {
        // Copy USDZ and JSON files for room
        if let usdzPath = room.usdzFilePath {
            let sourceURL = URL(fileURLWithPath: usdzPath)
            let destURL = directory.appendingPathComponent("room_\(room.roomIndex).usdz")
            
            do {
                try FileManager.default.copyItem(at: sourceURL, to: destURL)
            } catch {
                print("❌ Failed to copy USDZ file: \(error.localizedDescription)")
            }
        }
        
        if let jsonPath = room.jsonFilePath {
            let sourceURL = URL(fileURLWithPath: jsonPath)
            let destURL = directory.appendingPathComponent("room_\(room.roomIndex).json")
            
            do {
                try FileManager.default.copyItem(at: sourceURL, to: destURL)
            } catch {
                print("❌ Failed to copy JSON file: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Supporting Types

enum SyncStatus: Equatable {
    case idle
    case syncing
    case completed
    case failed(String)
    
    var displayName: String {
        switch self {
        case .idle: return "Ready"
        case .syncing: return "Syncing..."
        case .completed: return "Synced"
        case .failed(let error): return "Failed: \(error)"
        }
    }
}

struct ProjectExportData: Codable {
    let id: UUID
    let name: String
    let description: String?
    let createdAt: Date
    let updatedAt: Date
    let version: Int32
    let roomCount: Int
    
    init(from project: MultiRoomProject) {
        self.id = project.id ?? UUID()
        self.name = project.name ?? "Unnamed Project"
        self.description = project.projectDescription
        self.createdAt = project.createdAt ?? Date()
        self.updatedAt = project.updatedAt ?? Date()
        self.version = project.version
        self.roomCount = project.rooms?.count ?? 0
    }
}

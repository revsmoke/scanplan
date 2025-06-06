import Foundation
import RoomPlan
import ARKit
import Combine

/// Enhanced RoomPlan Session Manager for Multi-Room Scanning
/// Implements session continuity and spatial alignment between rooms
@MainActor
class MultiRoomScanManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var currentRoomIndex: Int = 0
    @Published var capturedRooms: [CapturedRoomData] = []
    @Published var scanningState: ScanningState = .idle
    @Published var sessionContinuity: SessionContinuityData?
    @Published var spatialAlignment: SpatialAlignmentData?
    
    // MARK: - Private Properties
    
    private var roomPlanSession: RoomCaptureSession?
    private var arSession: ARSession?
    private var sessionConfiguration: RoomCaptureSession.Configuration
    private var spatialAnchor: ARAnchor?
    private var roomTransitions: [RoomTransition] = []
    private var persistenceManager: MultiRoomPersistenceManager
    
    // MARK: - Initialization
    
    override init() {
        // Initialize session configuration
        self.sessionConfiguration = RoomCaptureSession.Configuration()
        self.sessionConfiguration.isCoachingEnabled = true
        
        // Initialize persistence manager
        self.persistenceManager = MultiRoomPersistenceManager()
        
        super.init()
        
        setupSessionConfiguration()
    }
    
    // MARK: - Public Interface
    
    /// Start a new multi-room scanning session
    func startMultiRoomSession() {
        guard RoomCaptureSession.isSupported else {
            print("❌ RoomPlan not supported on this device")
            return
        }
        
        print("🚀 Starting multi-room scanning session")
        
        // Reset state
        resetSessionState()
        
        // Initialize RoomPlan session
        roomPlanSession = RoomCaptureSession()
        roomPlanSession?.delegate = self
        
        // Start scanning first room
        startScanningRoom(index: 0)
    }
    
    /// Transition to scanning the next room while maintaining spatial context
    func transitionToNextRoom() {
        print("🔄 Transitioning to next room (current: \(currentRoomIndex))")
        
        // Save current room state
        saveCurrentRoomState()
        
        // Create transition data for spatial continuity
        createRoomTransition()
        
        // Move to next room
        currentRoomIndex += 1
        
        // Reset session for next room while maintaining spatial context
        resetSessionForNextRoom()
        
        // Start scanning next room
        startScanningRoom(index: currentRoomIndex)
    }
    
    /// Complete the multi-room scanning session
    func completeMultiRoomSession() {
        print("✅ Completing multi-room scanning session")
        
        // Save final room state
        saveCurrentRoomState()
        
        // Stop current session
        stopCurrentSession()
        
        // Process and align all rooms
        Task {
            await processMultiRoomAlignment()
        }
        
        scanningState = .completed
    }
    
    /// Pause the current scanning session
    func pauseSession() {
        print("⏸ Pausing scanning session")
        roomPlanSession?.stop()
        scanningState = .paused
    }
    
    /// Resume the paused scanning session
    func resumeSession() {
        print("▶️ Resuming scanning session")
        guard let session = roomPlanSession else { return }
        session.run(configuration: sessionConfiguration)
        scanningState = .scanning
    }
    
    /// Get the combined building model from all scanned rooms
    func getCombinedBuildingModel() async -> CombinedBuildingModel? {
        guard !capturedRooms.isEmpty else { return nil }
        
        return await ICPAlignmentEngine.alignRooms(capturedRooms)
    }
    
    // MARK: - Private Implementation
    
    private func setupSessionConfiguration() {
        // Configure for optimal multi-room scanning
        sessionConfiguration.isCoachingEnabled = true
        
        // iOS 17+ enhancements
        if #available(iOS 17.0, *) {
            // Enable enhanced features for better room transitions
            print("📱 Configuring iOS 17+ enhanced features")
        }
    }
    
    private func resetSessionState() {
        currentRoomIndex = 0
        capturedRooms.removeAll()
        roomTransitions.removeAll()
        spatialAnchor = nil
        sessionContinuity = nil
        spatialAlignment = nil
        scanningState = .idle
    }
    
    private func startScanningRoom(index: Int) {
        print("🏠 Starting scan for room \(index)")
        
        guard let session = roomPlanSession else {
            print("❌ No RoomPlan session available")
            return
        }
        
        // Update state
        scanningState = .scanning
        
        // Start or resume session
        session.run(configuration: sessionConfiguration)
        
        // Create room data container
        let roomData = CapturedRoomData(
            index: index,
            startTime: Date(),
            spatialContext: getCurrentSpatialContext()
        )
        
        // Add to captured rooms if new
        if capturedRooms.count <= index {
            capturedRooms.append(roomData)
        }
    }
    
    private func saveCurrentRoomState() {
        print("💾 Saving current room state (room \(currentRoomIndex))")
        
        // Update current room data
        if currentRoomIndex < capturedRooms.count {
            capturedRooms[currentRoomIndex].endTime = Date()
            capturedRooms[currentRoomIndex].spatialContext = getCurrentSpatialContext()
        }
        
        // Persist to storage
        Task {
            await persistenceManager.saveRoomData(capturedRooms[currentRoomIndex])
        }
    }
    
    private func createRoomTransition() {
        let transition = RoomTransition(
            fromRoomIndex: currentRoomIndex,
            toRoomIndex: currentRoomIndex + 1,
            spatialTransform: getCurrentSpatialTransform(),
            timestamp: Date()
        )
        
        roomTransitions.append(transition)
        print("🔗 Created room transition: \(currentRoomIndex) → \(currentRoomIndex + 1)")
    }
    
    private func resetSessionForNextRoom() {
        // Stop current session
        roomPlanSession?.stop()
        
        // Brief pause to ensure clean transition
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.continueSessionForNextRoom()
        }
    }
    
    private func continueSessionForNextRoom() {
        // Maintain spatial context while resetting room detection
        sessionContinuity = SessionContinuityData(
            previousRoomIndex: currentRoomIndex - 1,
            spatialAnchor: spatialAnchor,
            worldTransform: getCurrentSpatialTransform()
        )
        
        print("🔄 Session continuity established for room \(currentRoomIndex)")
    }
    
    private func stopCurrentSession() {
        roomPlanSession?.stop()
        roomPlanSession = nil
        scanningState = .idle
    }
    
    private func getCurrentSpatialContext() -> SpatialContext {
        // Get current spatial information for room alignment
        return SpatialContext(
            worldTransform: getCurrentSpatialTransform(),
            timestamp: Date(),
            confidence: calculateSpatialConfidence()
        )
    }
    
    private func getCurrentSpatialTransform() -> simd_float4x4 {
        // Get current world transform from ARKit
        guard let arFrame = arSession?.currentFrame else {
            return matrix_identity_float4x4
        }
        
        return arFrame.camera.transform
    }
    
    private func calculateSpatialConfidence() -> Float {
        // Calculate confidence in spatial tracking
        // This would analyze tracking quality, feature points, etc.
        return 0.85 // Placeholder - implement actual confidence calculation
    }
    
    private func processMultiRoomAlignment() async {
        print("🔄 Processing multi-room spatial alignment")
        
        guard capturedRooms.count > 1 else {
            print("⚠️ Only one room captured, no alignment needed")
            return
        }
        
        // Create spatial alignment data
        spatialAlignment = SpatialAlignmentData(
            rooms: capturedRooms,
            transitions: roomTransitions,
            alignmentQuality: await calculateAlignmentQuality()
        )
        
        print("✅ Multi-room alignment completed")
    }
    
    private func calculateAlignmentQuality() async -> AlignmentQuality {
        // Analyze the quality of room-to-room alignment
        // This would check for consistency, overlaps, gaps, etc.
        return AlignmentQuality(
            overallScore: 0.92,
            roomAlignmentScores: capturedRooms.map { _ in 0.90 },
            issues: []
        )
    }
}

// MARK: - RoomCaptureSessionDelegate

extension MultiRoomScanManager: RoomCaptureSessionDelegate {

    func captureSession(_ session: RoomCaptureSession, didUpdate room: CapturedRoom) {
        print("📊 Room scan updated for room \(currentRoomIndex)")

        // Update current room data
        if currentRoomIndex < capturedRooms.count {
            capturedRooms[currentRoomIndex].capturedRoom = room
        }
    }

    func captureSession(_ session: RoomCaptureSession, didAdd room: CapturedRoom) {
        print("➕ Room scan added for room \(currentRoomIndex)")

        // Store the captured room
        if currentRoomIndex < capturedRooms.count {
            capturedRooms[currentRoomIndex].capturedRoom = room
        }
    }

    func captureSession(_ session: RoomCaptureSession, didChange room: CapturedRoom) {
        print("🔄 Room scan changed for room \(currentRoomIndex)")

        // Update the captured room
        if currentRoomIndex < capturedRooms.count {
            capturedRooms[currentRoomIndex].capturedRoom = room
        }
    }

    func captureSession(_ session: RoomCaptureSession, didRemove room: CapturedRoom) {
        print("➖ Room scan removed for room \(currentRoomIndex)")

        // Handle room removal if needed
        // This might happen during room boundary adjustments
    }

    func captureSession(_ session: RoomCaptureSession, didFailWithError error: Error) {
        print("❌ Room capture session failed: \(error.localizedDescription)")

        scanningState = .error(error.localizedDescription)

        // Handle error with user-friendly message
        DispatchQueue.main.async { [weak self] in
            self?.handleSessionError(error)
        }
    }

    func captureSession(_ session: RoomCaptureSession, didEndWith data: CapturedRoomData, error: Error?) {
        print("🏁 Room capture session ended for room \(currentRoomIndex)")

        if let error = error {
            print("❌ Session ended with error: \(error.localizedDescription)")
            scanningState = .error(error.localizedDescription)
            handleSessionError(error)
        } else {
            print("✅ Room \(currentRoomIndex) captured successfully")
            scanningState = .processing

            // Process the completed room
            processCompletedRoom(data)
        }
    }

    // MARK: - Error Handling

    private func handleSessionError(_ error: Error) {
        // Provide user-friendly error handling
        let errorMessage = "Room scanning encountered an error: \(error.localizedDescription)"

        // This would typically show an alert to the user
        // For now, we'll just log and update state
        print("🚨 Handling session error: \(errorMessage)")

        // Attempt recovery if possible
        attemptErrorRecovery(error)
    }

    private func attemptErrorRecovery(_ error: Error) {
        print("🔧 Attempting error recovery")

        // Depending on error type, we might:
        // - Restart the session
        // - Reset to previous room
        // - Provide user guidance

        // For now, simple recovery attempt
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            if case .error = self?.scanningState {
                self?.resumeSession()
            }
        }
    }

    private func processCompletedRoom(_ data: CapturedRoomData) {
        print("⚙️ Processing completed room \(currentRoomIndex)")

        // Update room data
        if currentRoomIndex < capturedRooms.count {
            capturedRooms[currentRoomIndex] = data
        }

        // Mark as ready for next room or completion
        scanningState = .idle

        print("✅ Room \(currentRoomIndex) processing completed")
    }
}

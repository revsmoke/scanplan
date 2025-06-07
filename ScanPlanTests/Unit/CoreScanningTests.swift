import XCTest
import ARKit
import RealityKit
@testable import ScanPlan

/// Comprehensive unit tests for core scanning functionality
/// Tests the foundation of our spatial analysis platform
class CoreScanningTests: XCTestCase {
    
    // MARK: - Test Properties
    
    var scanningManager: ScanningManager!
    var testPointCloud: PointCloud!
    var testMesh: Mesh!
    var performanceMetrics: PerformanceMetrics!
    
    // MARK: - Setup and Teardown
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Initialize scanning manager
        scanningManager = ScanningManager()
        
        // Create test data
        testPointCloud = createTestPointCloud()
        testMesh = createTestMesh()
        performanceMetrics = PerformanceMetrics()
        
        print("🧪 Setting up CoreScanningTests")
    }
    
    override func tearDownWithError() throws {
        scanningManager = nil
        testPointCloud = nil
        testMesh = nil
        performanceMetrics = nil
        
        print("🧹 Tearing down CoreScanningTests")
        try super.tearDownWithError()
    }
    
    // MARK: - Scanning Manager Tests
    
    func testScanningManagerInitialization() throws {
        // Test scanning manager initialization
        XCTAssertNotNil(scanningManager, "Scanning manager should initialize successfully")
        XCTAssertEqual(scanningManager.scanningState, .idle, "Initial state should be idle")
        XCTAssertTrue(scanningManager.isARKitSupported, "ARKit should be supported")
        
        print("✅ Scanning manager initialization test passed")
    }
    
    func testScanningConfiguration() throws {
        // Test scanning configuration
        let config = ScanningConfiguration.professional()
        
        XCTAssertEqual(config.accuracy, .subCentimeter, "Professional config should use sub-centimeter accuracy")
        XCTAssertEqual(config.quality, .high, "Professional config should use high quality")
        XCTAssertTrue(config.enableRealTimeProcessing, "Real-time processing should be enabled")
        
        // Apply configuration
        scanningManager.configure(with: config)
        XCTAssertEqual(scanningManager.currentConfiguration.accuracy, .subCentimeter)
        
        print("✅ Scanning configuration test passed")
    }
    
    func testScanningStateTransitions() throws {
        // Test state transitions
        XCTAssertEqual(scanningManager.scanningState, .idle)
        
        // Start scanning
        scanningManager.startScanning()
        XCTAssertEqual(scanningManager.scanningState, .scanning)
        
        // Pause scanning
        scanningManager.pauseScanning()
        XCTAssertEqual(scanningManager.scanningState, .paused)
        
        // Resume scanning
        scanningManager.resumeScanning()
        XCTAssertEqual(scanningManager.scanningState, .scanning)
        
        // Stop scanning
        scanningManager.stopScanning()
        XCTAssertEqual(scanningManager.scanningState, .idle)
        
        print("✅ Scanning state transitions test passed")
    }
    
    // MARK: - Point Cloud Tests
    
    func testPointCloudGeneration() throws {
        // Test point cloud generation
        let pointCloud = scanningManager.generatePointCloud(from: createTestARFrame())
        
        XCTAssertNotNil(pointCloud, "Point cloud should be generated")
        XCTAssertGreaterThan(pointCloud.points.count, 0, "Point cloud should contain points")
        XCTAssertTrue(pointCloud.isValid, "Point cloud should be valid")
        
        print("✅ Point cloud generation test passed")
    }
    
    func testPointCloudAccuracy() throws {
        // Test point cloud accuracy
        let accuracy = testPointCloud.calculateAccuracy()
        
        XCTAssertLessThanOrEqual(accuracy.averageError, 0.01, "Average error should be ≤ 1cm (sub-centimeter)")
        XCTAssertLessThanOrEqual(accuracy.maxError, 0.05, "Max error should be ≤ 5cm")
        XCTAssertGreaterThanOrEqual(accuracy.confidence, 0.95, "Confidence should be ≥ 95%")
        
        print("✅ Point cloud accuracy test passed - Average error: \(accuracy.averageError)m")
    }
    
    func testPointCloudProcessing() throws {
        // Test point cloud processing
        let processedCloud = scanningManager.processPointCloud(testPointCloud)
        
        XCTAssertNotNil(processedCloud, "Processed point cloud should not be nil")
        XCTAssertLessThanOrEqual(processedCloud.noiseLevel, 0.02, "Noise level should be reduced")
        XCTAssertGreaterThanOrEqual(processedCloud.density, testPointCloud.density, "Density should be maintained or improved")
        
        print("✅ Point cloud processing test passed")
    }
    
    // MARK: - Mesh Generation Tests
    
    func testMeshGeneration() throws {
        // Test mesh generation from point cloud
        let mesh = scanningManager.generateMesh(from: testPointCloud)
        
        XCTAssertNotNil(mesh, "Mesh should be generated")
        XCTAssertGreaterThan(mesh.vertices.count, 0, "Mesh should have vertices")
        XCTAssertGreaterThan(mesh.faces.count, 0, "Mesh should have faces")
        XCTAssertTrue(mesh.isManifold, "Mesh should be manifold")
        
        print("✅ Mesh generation test passed")
    }
    
    func testMeshQuality() throws {
        // Test mesh quality
        let quality = testMesh.assessQuality()
        
        XCTAssertGreaterThanOrEqual(quality.overallScore, 0.8, "Overall quality should be ≥ 80%")
        XCTAssertLessThanOrEqual(quality.aspectRatio, 3.0, "Aspect ratio should be reasonable")
        XCTAssertGreaterThanOrEqual(quality.manifoldness, 0.95, "Manifoldness should be ≥ 95%")
        
        print("✅ Mesh quality test passed - Quality score: \(quality.overallScore)")
    }
    
    func testMeshOptimization() throws {
        // Test mesh optimization
        let originalVertexCount = testMesh.vertices.count
        let optimizedMesh = scanningManager.optimizeMesh(testMesh)
        
        XCTAssertNotNil(optimizedMesh, "Optimized mesh should not be nil")
        XCTAssertLessThanOrEqual(optimizedMesh.vertices.count, originalVertexCount, "Vertex count should be reduced or maintained")
        XCTAssertGreaterThanOrEqual(optimizedMesh.assessQuality().overallScore, testMesh.assessQuality().overallScore, "Quality should be maintained or improved")
        
        print("✅ Mesh optimization test passed")
    }
    
    // MARK: - Performance Tests
    
    func testScanningPerformance() throws {
        // Test scanning performance
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Perform scanning operations
        for _ in 0..<100 {
            let frame = createTestARFrame()
            let pointCloud = scanningManager.generatePointCloud(from: frame)
            XCTAssertNotNil(pointCloud)
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        let fps = 100.0 / duration
        
        XCTAssertGreaterThanOrEqual(fps, 30.0, "Scanning should achieve ≥ 30 FPS")
        
        print("✅ Scanning performance test passed - FPS: \(fps)")
    }
    
    func testMemoryUsage() throws {
        // Test memory usage during scanning
        let initialMemory = getMemoryUsage()
        
        // Perform memory-intensive operations
        var pointClouds: [PointCloud] = []
        for _ in 0..<50 {
            let pointCloud = scanningManager.generatePointCloud(from: createTestARFrame())
            pointClouds.append(pointCloud)
        }
        
        let peakMemory = getMemoryUsage()
        let memoryIncrease = peakMemory - initialMemory
        
        // Clean up
        pointClouds.removeAll()
        
        let finalMemory = getMemoryUsage()
        let memoryLeakage = finalMemory - initialMemory
        
        XCTAssertLessThan(memoryIncrease, 500_000_000, "Memory increase should be < 500MB") // 500MB limit
        XCTAssertLessThan(memoryLeakage, 50_000_000, "Memory leakage should be < 50MB") // 50MB limit
        
        print("✅ Memory usage test passed - Increase: \(memoryIncrease / 1_000_000)MB, Leakage: \(memoryLeakage / 1_000_000)MB")
    }
    
    // MARK: - Accuracy Tests
    
    func testSubCentimeterAccuracy() throws {
        // Test sub-centimeter accuracy requirement
        let referencePoints = createReferencePoints()
        let scannedPoints = scanningManager.scanPoints(referencePoints)
        
        for (reference, scanned) in zip(referencePoints, scannedPoints) {
            let distance = simd_distance(reference, scanned)
            XCTAssertLessThanOrEqual(distance, 0.01, "Distance error should be ≤ 1cm (sub-centimeter)")
        }
        
        print("✅ Sub-centimeter accuracy test passed")
    }
    
    func testPrecisionConsistency() throws {
        // Test precision consistency across multiple scans
        let referenceObject = createReferenceObject()
        var measurements: [Float] = []
        
        // Perform multiple measurements
        for _ in 0..<10 {
            let measurement = scanningManager.measureObject(referenceObject)
            measurements.append(measurement.volume)
        }
        
        // Calculate standard deviation
        let mean = measurements.reduce(0, +) / Float(measurements.count)
        let variance = measurements.map { pow($0 - mean, 2) }.reduce(0, +) / Float(measurements.count)
        let standardDeviation = sqrt(variance)
        
        XCTAssertLessThanOrEqual(standardDeviation, 0.001, "Standard deviation should be ≤ 0.1% for consistency")
        
        print("✅ Precision consistency test passed - StdDev: \(standardDeviation)")
    }
    
    // MARK: - Helper Methods
    
    private func createTestPointCloud() -> PointCloud {
        // Create a test point cloud with known properties
        var points: [SIMD3<Float>] = []
        
        // Generate a cube of points
        for x in stride(from: -1.0, through: 1.0, by: 0.1) {
            for y in stride(from: -1.0, through: 1.0, by: 0.1) {
                for z in stride(from: -1.0, through: 1.0, by: 0.1) {
                    points.append(SIMD3<Float>(x, y, z))
                }
            }
        }
        
        return PointCloud(points: points, colors: nil, normals: nil)
    }
    
    private func createTestMesh() -> Mesh {
        // Create a test mesh (simple cube)
        let vertices: [SIMD3<Float>] = [
            SIMD3<Float>(-1, -1, -1), SIMD3<Float>(1, -1, -1),
            SIMD3<Float>(1, 1, -1), SIMD3<Float>(-1, 1, -1),
            SIMD3<Float>(-1, -1, 1), SIMD3<Float>(1, -1, 1),
            SIMD3<Float>(1, 1, 1), SIMD3<Float>(-1, 1, 1)
        ]
        
        let faces: [SIMD3<UInt32>] = [
            SIMD3<UInt32>(0, 1, 2), SIMD3<UInt32>(0, 2, 3), // Front
            SIMD3<UInt32>(4, 7, 6), SIMD3<UInt32>(4, 6, 5), // Back
            SIMD3<UInt32>(0, 4, 5), SIMD3<UInt32>(0, 5, 1), // Bottom
            SIMD3<UInt32>(2, 6, 7), SIMD3<UInt32>(2, 7, 3), // Top
            SIMD3<UInt32>(0, 3, 7), SIMD3<UInt32>(0, 7, 4), // Left
            SIMD3<UInt32>(1, 5, 6), SIMD3<UInt32>(1, 6, 2)  // Right
        ]
        
        return Mesh(vertices: vertices, faces: faces, normals: nil, textureCoordinates: nil)
    }
    
    private func createTestARFrame() -> ARFrame {
        // Create a mock ARFrame for testing
        // In real implementation, this would be a proper ARFrame
        return ARFrame() // Simplified for testing
    }
    
    private func createReferencePoints() -> [SIMD3<Float>] {
        // Create reference points with known positions
        return [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(1, 0, 0),
            SIMD3<Float>(0, 1, 0),
            SIMD3<Float>(0, 0, 1),
            SIMD3<Float>(1, 1, 1)
        ]
    }
    
    private func createReferenceObject() -> ReferenceObject {
        // Create a reference object with known dimensions
        return ReferenceObject(
            dimensions: SIMD3<Float>(1.0, 1.0, 1.0),
            volume: 1.0,
            surfaceArea: 6.0
        )
    }
    
    private func getMemoryUsage() -> Int64 {
        // Get current memory usage
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        return result == KERN_SUCCESS ? Int64(info.resident_size) : 0
    }
}

// MARK: - Supporting Structures

struct ReferenceObject {
    let dimensions: SIMD3<Float>
    let volume: Float
    let surfaceArea: Float
}

struct PerformanceMetrics {
    var fps: Float = 0.0
    var memoryUsage: Int64 = 0
    var processingTime: TimeInterval = 0.0
}

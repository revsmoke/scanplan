import XCTest
import Foundation
@testable import ScanPlan

/// Comprehensive unit tests for export pipeline functionality
/// Tests all 13 export formats and 8 industry workflows
class ExportPipelineTests: XCTestCase {
    
    // MARK: - Test Properties
    
    var exportManager: ExportManager!
    var testScanData: ScanData!
    var testMesh: Mesh!
    var qualityController: ExportQualityController!
    
    // MARK: - Setup and Teardown
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Initialize export manager
        exportManager = ExportManager()
        
        // Create test data
        testScanData = createTestScanData()
        testMesh = createTestMesh()
        qualityController = ExportQualityController()
        
        print("🧪 Setting up ExportPipelineTests")
    }
    
    override func tearDownWithError() throws {
        exportManager = nil
        testScanData = nil
        testMesh = nil
        qualityController = nil
        
        print("🧹 Tearing down ExportPipelineTests")
        try super.tearDownWithError()
    }
    
    // MARK: - Export Manager Tests
    
    func testExportManagerInitialization() throws {
        XCTAssertNotNil(exportManager, "Export manager should initialize successfully")
        XCTAssertEqual(exportManager.supportedFormats.count, 13, "Should support 13 export formats")
        XCTAssertEqual(exportManager.supportedWorkflows.count, 8, "Should support 8 industry workflows")
        
        print("✅ Export manager initialization test passed")
    }
    
    func testSupportedFormats() throws {
        let expectedFormats: [ExportFormat] = [
            .obj, .ply, .stl, .fbx, .gltf, .usd, .ifc4, .e57,
            .autocad, .rhino, .revit, .sketchup, .blender
        ]
        
        for format in expectedFormats {
            XCTAssertTrue(exportManager.supportsFormat(format), "Should support \(format.rawValue) format")
        }
        
        print("✅ Supported formats test passed")
    }
    
    func testSupportedWorkflows() throws {
        let expectedWorkflows: [IndustryWorkflow] = [
            .architecture, .engineering, .construction, .manufacturing,
            .gaming, .vfx, .research, .preservation
        ]
        
        for workflow in expectedWorkflows {
            XCTAssertTrue(exportManager.supportsWorkflow(workflow), "Should support \(workflow.rawValue) workflow")
        }
        
        print("✅ Supported workflows test passed")
    }
    
    // MARK: - Format-Specific Export Tests
    
    func testOBJExport() throws {
        // Test OBJ format export
        let exportConfig = ExportConfiguration(
            format: .obj,
            quality: .high,
            includeTextures: true,
            includeMaterials: true
        )
        
        let result = try exportManager.exportScanData(testScanData, configuration: exportConfig)
        
        XCTAssertTrue(result.isSuccessful, "OBJ export should succeed")
        XCTAssertNotNil(result.fileURL, "Should generate file URL")
        XCTAssertTrue(result.fileURL!.pathExtension == "obj", "Should have .obj extension")
        
        // Validate OBJ file content
        let objContent = try String(contentsOf: result.fileURL!)
        XCTAssertTrue(objContent.contains("v "), "Should contain vertices")
        XCTAssertTrue(objContent.contains("f "), "Should contain faces")
        
        print("✅ OBJ export test passed")
    }
    
    func testPLYExport() throws {
        // Test PLY format export
        let exportConfig = ExportConfiguration(
            format: .ply,
            quality: .high,
            includeColors: true,
            includeNormals: true
        )
        
        let result = try exportManager.exportScanData(testScanData, configuration: exportConfig)
        
        XCTAssertTrue(result.isSuccessful, "PLY export should succeed")
        XCTAssertTrue(result.fileURL!.pathExtension == "ply", "Should have .ply extension")
        
        // Validate PLY file structure
        let plyContent = try String(contentsOf: result.fileURL!)
        XCTAssertTrue(plyContent.contains("ply"), "Should contain PLY header")
        XCTAssertTrue(plyContent.contains("element vertex"), "Should contain vertex elements")
        
        print("✅ PLY export test passed")
    }
    
    func testSTLExport() throws {
        // Test STL format export
        let exportConfig = ExportConfiguration(
            format: .stl,
            quality: .high,
            binaryFormat: true
        )
        
        let result = try exportManager.exportScanData(testScanData, configuration: exportConfig)
        
        XCTAssertTrue(result.isSuccessful, "STL export should succeed")
        XCTAssertTrue(result.fileURL!.pathExtension == "stl", "Should have .stl extension")
        
        // Validate STL file size (binary STL should be compact)
        let fileSize = try FileManager.default.attributesOfItem(atPath: result.fileURL!.path)[.size] as! Int64
        XCTAssertGreaterThan(fileSize, 0, "STL file should not be empty")
        
        print("✅ STL export test passed")
    }
    
    func testFBXExport() throws {
        // Test FBX format export (complex format)
        let exportConfig = ExportConfiguration(
            format: .fbx,
            quality: .high,
            includeAnimations: false,
            includeMaterials: true
        )
        
        let result = try exportManager.exportScanData(testScanData, configuration: exportConfig)
        
        XCTAssertTrue(result.isSuccessful, "FBX export should succeed")
        XCTAssertTrue(result.fileURL!.pathExtension == "fbx", "Should have .fbx extension")
        
        print("✅ FBX export test passed")
    }
    
    func testGLTFExport() throws {
        // Test glTF format export (modern web format)
        let exportConfig = ExportConfiguration(
            format: .gltf,
            quality: .high,
            includeTextures: true,
            optimizeForWeb: true
        )
        
        let result = try exportManager.exportScanData(testScanData, configuration: exportConfig)
        
        XCTAssertTrue(result.isSuccessful, "glTF export should succeed")
        XCTAssertTrue(result.fileURL!.pathExtension == "gltf", "Should have .gltf extension")
        
        // Validate glTF JSON structure
        let gltfData = try Data(contentsOf: result.fileURL!)
        let gltfJSON = try JSONSerialization.jsonObject(with: gltfData) as! [String: Any]
        XCTAssertNotNil(gltfJSON["asset"], "Should contain asset information")
        XCTAssertNotNil(gltfJSON["scenes"], "Should contain scenes")
        
        print("✅ glTF export test passed")
    }
    
    func testIFC4Export() throws {
        // Test IFC4 format export (BIM format)
        let exportConfig = ExportConfiguration(
            format: .ifc4,
            quality: .high,
            includeBIMData: true,
            includeMetadata: true
        )
        
        let result = try exportManager.exportScanData(testScanData, configuration: exportConfig)
        
        XCTAssertTrue(result.isSuccessful, "IFC4 export should succeed")
        XCTAssertTrue(result.fileURL!.pathExtension == "ifc", "Should have .ifc extension")
        
        // Validate IFC4 file structure
        let ifcContent = try String(contentsOf: result.fileURL!)
        XCTAssertTrue(ifcContent.contains("ISO-10303-21"), "Should contain IFC header")
        XCTAssertTrue(ifcContent.contains("IFC4"), "Should be IFC4 version")
        
        print("✅ IFC4 export test passed")
    }
    
    // MARK: - Industry Workflow Tests
    
    func testArchitectureWorkflow() throws {
        // Test architecture industry workflow
        let workflow = IndustryWorkflow.architecture
        let exportConfig = exportManager.getOptimizedConfiguration(for: workflow)
        
        XCTAssertEqual(exportConfig.format, .ifc4, "Architecture should prefer IFC4 format")
        XCTAssertTrue(exportConfig.includeBIMData, "Should include BIM data for architecture")
        XCTAssertTrue(exportConfig.includeMetadata, "Should include metadata")
        
        let result = try exportManager.exportWithWorkflow(testScanData, workflow: workflow)
        XCTAssertTrue(result.isSuccessful, "Architecture workflow export should succeed")
        
        print("✅ Architecture workflow test passed")
    }
    
    func testEngineeringWorkflow() throws {
        // Test engineering industry workflow
        let workflow = IndustryWorkflow.engineering
        let exportConfig = exportManager.getOptimizedConfiguration(for: workflow)
        
        XCTAssertEqual(exportConfig.format, .step, "Engineering should prefer STEP format")
        XCTAssertTrue(exportConfig.includePrecisionData, "Should include precision data")
        XCTAssertEqual(exportConfig.units, .millimeters, "Should use millimeters for precision")
        
        let result = try exportManager.exportWithWorkflow(testScanData, workflow: workflow)
        XCTAssertTrue(result.isSuccessful, "Engineering workflow export should succeed")
        
        print("✅ Engineering workflow test passed")
    }
    
    func testManufacturingWorkflow() throws {
        // Test manufacturing industry workflow
        let workflow = IndustryWorkflow.manufacturing
        let exportConfig = exportManager.getOptimizedConfiguration(for: workflow)
        
        XCTAssertEqual(exportConfig.format, .stl, "Manufacturing should prefer STL format")
        XCTAssertTrue(exportConfig.optimizeForPrinting, "Should optimize for 3D printing")
        XCTAssertTrue(exportConfig.validateManifold, "Should validate manifold geometry")
        
        let result = try exportManager.exportWithWorkflow(testScanData, workflow: workflow)
        XCTAssertTrue(result.isSuccessful, "Manufacturing workflow export should succeed")
        
        print("✅ Manufacturing workflow test passed")
    }
    
    func testGamingWorkflow() throws {
        // Test gaming industry workflow
        let workflow = IndustryWorkflow.gaming
        let exportConfig = exportManager.getOptimizedConfiguration(for: workflow)
        
        XCTAssertEqual(exportConfig.format, .fbx, "Gaming should prefer FBX format")
        XCTAssertTrue(exportConfig.optimizeForRealTime, "Should optimize for real-time rendering")
        XCTAssertTrue(exportConfig.generateLODs, "Should generate LOD levels")
        
        let result = try exportManager.exportWithWorkflow(testScanData, workflow: workflow)
        XCTAssertTrue(result.isSuccessful, "Gaming workflow export should succeed")
        
        print("✅ Gaming workflow test passed")
    }
    
    // MARK: - Quality Control Tests
    
    func testExportQualityValidation() throws {
        // Test export quality validation
        let exportConfig = ExportConfiguration(format: .obj, quality: .high)
        let result = try exportManager.exportScanData(testScanData, configuration: exportConfig)
        
        // Validate export quality
        let qualityReport = try qualityController.validateExport(result)
        
        XCTAssertGreaterThanOrEqual(qualityReport.overallScore, 0.9, "Quality score should be ≥ 90%")
        XCTAssertTrue(qualityReport.geometryIntegrity, "Geometry integrity should be maintained")
        XCTAssertTrue(qualityReport.formatCompliance, "Should comply with format standards")
        XCTAssertLessThanOrEqual(qualityReport.dataLoss, 0.01, "Data loss should be ≤ 1%")
        
        print("✅ Export quality validation test passed - Score: \(qualityReport.overallScore)")
    }
    
    func testFileIntegrityValidation() throws {
        // Test file integrity validation
        let exportConfig = ExportConfiguration(format: .ply, quality: .high)
        let result = try exportManager.exportScanData(testScanData, configuration: exportConfig)
        
        // Validate file integrity
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.fileURL!.path), "Export file should exist")
        
        let fileSize = try FileManager.default.attributesOfItem(atPath: result.fileURL!.path)[.size] as! Int64
        XCTAssertGreaterThan(fileSize, 0, "Export file should not be empty")
        
        // Validate file can be read back
        let reimportedData = try exportManager.importFile(result.fileURL!)
        XCTAssertNotNil(reimportedData, "Exported file should be readable")
        
        print("✅ File integrity validation test passed")
    }
    
    func testMetadataPreservation() throws {
        // Test metadata preservation during export
        testScanData.metadata["scan_date"] = "2024-01-01"
        testScanData.metadata["scanner_model"] = "ScanPlan Pro"
        testScanData.metadata["accuracy"] = "sub-centimeter"
        
        let exportConfig = ExportConfiguration(
            format: .obj,
            quality: .high,
            includeMetadata: true
        )
        
        let result = try exportManager.exportScanData(testScanData, configuration: exportConfig)
        
        // Validate metadata preservation
        XCTAssertNotNil(result.metadata, "Metadata should be preserved")
        XCTAssertEqual(result.metadata!["scan_date"], "2024-01-01", "Scan date should be preserved")
        XCTAssertEqual(result.metadata!["scanner_model"], "ScanPlan Pro", "Scanner model should be preserved")
        
        print("✅ Metadata preservation test passed")
    }
    
    // MARK: - Performance Tests
    
    func testExportPerformance() throws {
        // Test export performance
        let exportConfig = ExportConfiguration(format: .obj, quality: .high)
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try exportManager.exportScanData(testScanData, configuration: exportConfig)
        let endTime = CFAbsoluteTimeGetCurrent()
        
        let exportTime = endTime - startTime
        
        XCTAssertTrue(result.isSuccessful, "Export should succeed")
        XCTAssertLessThan(exportTime, 30.0, "Export should complete within 30 seconds")
        
        print("✅ Export performance test passed - Time: \(exportTime)s")
    }
    
    func testBatchExportPerformance() throws {
        // Test batch export performance
        let formats: [ExportFormat] = [.obj, .ply, .stl, .fbx, .gltf]
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for format in formats {
            let exportConfig = ExportConfiguration(format: format, quality: .medium)
            let result = try exportManager.exportScanData(testScanData, configuration: exportConfig)
            XCTAssertTrue(result.isSuccessful, "\(format.rawValue) export should succeed")
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let totalTime = endTime - startTime
        
        XCTAssertLessThan(totalTime, 60.0, "Batch export should complete within 60 seconds")
        
        print("✅ Batch export performance test passed - Total time: \(totalTime)s")
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidFormatHandling() throws {
        // Test handling of invalid export configurations
        let invalidConfig = ExportConfiguration(
            format: .obj,
            quality: .high,
            outputPath: "/invalid/path/that/does/not/exist"
        )
        
        XCTAssertThrowsError(try exportManager.exportScanData(testScanData, configuration: invalidConfig)) { error in
            XCTAssertTrue(error is ExportError, "Should throw ExportError")
        }
        
        print("✅ Invalid format handling test passed")
    }
    
    func testCorruptedDataHandling() throws {
        // Test handling of corrupted scan data
        let corruptedData = ScanData(
            pointCloud: PointCloud(points: [], colors: nil, normals: nil),
            mesh: nil,
            metadata: [:]
        )
        
        let exportConfig = ExportConfiguration(format: .obj, quality: .high)
        
        XCTAssertThrowsError(try exportManager.exportScanData(corruptedData, configuration: exportConfig)) { error in
            XCTAssertTrue(error is ExportError, "Should throw ExportError for corrupted data")
        }
        
        print("✅ Corrupted data handling test passed")
    }
    
    // MARK: - Helper Methods
    
    private func createTestScanData() -> ScanData {
        let pointCloud = createTestPointCloud()
        let mesh = createTestMesh()
        let metadata = [
            "scan_id": UUID().uuidString,
            "scan_date": ISO8601DateFormatter().string(from: Date()),
            "accuracy": "sub-centimeter",
            "point_count": "\(pointCloud.points.count)"
        ]
        
        return ScanData(
            pointCloud: pointCloud,
            mesh: mesh,
            metadata: metadata
        )
    }
    
    private func createTestPointCloud() -> PointCloud {
        var points: [SIMD3<Float>] = []
        var colors: [SIMD3<Float>] = []
        
        // Generate test points in a cube pattern
        for x in stride(from: -1.0, through: 1.0, by: 0.2) {
            for y in stride(from: -1.0, through: 1.0, by: 0.2) {
                for z in stride(from: -1.0, through: 1.0, by: 0.2) {
                    points.append(SIMD3<Float>(x, y, z))
                    colors.append(SIMD3<Float>(Float.random(in: 0...1), Float.random(in: 0...1), Float.random(in: 0...1)))
                }
            }
        }
        
        return PointCloud(points: points, colors: colors, normals: nil)
    }
    
    private func createTestMesh() -> Mesh {
        // Create a simple test mesh (cube)
        let vertices: [SIMD3<Float>] = [
            SIMD3<Float>(-1, -1, -1), SIMD3<Float>(1, -1, -1),
            SIMD3<Float>(1, 1, -1), SIMD3<Float>(-1, 1, -1),
            SIMD3<Float>(-1, -1, 1), SIMD3<Float>(1, -1, 1),
            SIMD3<Float>(1, 1, 1), SIMD3<Float>(-1, 1, 1)
        ]
        
        let faces: [SIMD3<UInt32>] = [
            SIMD3<UInt32>(0, 1, 2), SIMD3<UInt32>(0, 2, 3),
            SIMD3<UInt32>(4, 7, 6), SIMD3<UInt32>(4, 6, 5),
            SIMD3<UInt32>(0, 4, 5), SIMD3<UInt32>(0, 5, 1),
            SIMD3<UInt32>(2, 6, 7), SIMD3<UInt32>(2, 7, 3),
            SIMD3<UInt32>(0, 3, 7), SIMD3<UInt32>(0, 7, 4),
            SIMD3<UInt32>(1, 5, 6), SIMD3<UInt32>(1, 6, 2)
        ]
        
        return Mesh(vertices: vertices, faces: faces, normals: nil, textureCoordinates: nil)
    }
}

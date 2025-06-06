import UIKit
import SceneKit

extension ResultsViewController {
    
    // MARK: - Performance Optimizations
    
    func configureSceneViewPerformance() {
        // Adaptive quality based on device capabilities
        let processorCount = ProcessInfo.processInfo.processorCount
        let physicalMemory = ProcessInfo.processInfo.physicalMemory
        
        // Configure antialiasing based on device performance
        if processorCount >= 6 && physicalMemory > 4_000_000_000 { // 4GB+
            sceneView.antialiasingMode = .multisampling4X
        } else if processorCount >= 4 {
            sceneView.antialiasingMode = .multisampling2X
        } else {
            sceneView.antialiasingMode = .none
        }
        
        // Configure frame rate
        sceneView.preferredFramesPerSecond = 60
        
        // Enable performance monitoring in debug builds
        #if DEBUG
        sceneView.showsStatistics = false // Set to true for debugging
        #endif
        
        // Configure rendering options for better performance
        sceneView.rendersContinuously = false // Only render when needed
        sceneView.jitteringEnabled = true // Reduce aliasing
        
        // Configure scene options
        sceneView.scene?.fogStartDistance = 10
        sceneView.scene?.fogEndDistance = 50
        sceneView.scene?.fogDensityExponent = 1.0
        
        print("SceneKit configured for device with \(processorCount) cores and \(ByteCountFormatter.string(fromByteCount: Int64(physicalMemory), countStyle: .memory)) RAM")
    }
    
    func optimizeSceneForPerformance(_ scene: SCNScene) {
        // Optimize geometry for better performance
        scene.rootNode.enumerateChildNodes { node, _ in
            if let geometry = node.geometry {
                // Enable automatic normal generation if needed
                geometry.setValue(true, forKey: "kSCNGeometrySourceSemanticNormal")
                
                // Optimize materials
                for material in geometry.materials {
                    // Use simpler shading models for better performance
                    material.lightingModel = .lambert
                    
                    // Disable expensive material features if not needed
                    material.isDoubleSided = false
                    
                    // Optimize texture settings
                    if let diffuse = material.diffuse.contents as? UIImage {
                        // Ensure textures are power of 2 for better GPU performance
                        material.diffuse.wrapS = .repeat
                        material.diffuse.wrapT = .repeat
                        material.diffuse.mipFilter = .linear
                    }
                }
            }
        }
        
        // Set up level of detail if needed for complex scenes
        setupLevelOfDetail(for: scene)
    }
    
    private func setupLevelOfDetail(for scene: SCNScene) {
        // Implement LOD for complex furniture objects
        scene.rootNode.enumerateChildNodes { node, _ in
            if let geometry = node.geometry,
               geometry.primitiveCount > 1000 { // High poly count objects
                
                // Create simplified version for distant viewing
                let simplifiedGeometry = geometry.copy() as! SCNGeometry
                
                // Reduce detail (this is a simplified example)
                // In a real implementation, you'd use proper mesh decimation
                let lodNode = SCNNode(geometry: simplifiedGeometry)
                
                // Set up distance-based LOD
                node.addChildNode(lodNode)
            }
        }
    }
    
    // MARK: - Memory Management
    
    func optimizeMemoryUsage() {
        // Clean up unused resources
        sceneView.scene?.rootNode.enumerateChildNodes { node, _ in
            // Remove nodes that are far from camera or not visible
            if !isNodeVisible(node) {
                node.removeFromParentNode()
            }
        }
        
        // Force garbage collection of unused SceneKit resources
        sceneView.scene?.rootNode.cleanup()
    }
    
    private func isNodeVisible(_ node: SCNNode) -> Bool {
        // Simple visibility check based on distance from camera
        guard let camera = sceneView.pointOfView else { return true }
        
        let distance = simd_distance(node.simdPosition, camera.simdPosition)
        return distance < 20.0 // 20 meter visibility range
    }
    
    // MARK: - Adaptive Quality
    
    func adjustQualityBasedOnPerformance() {
        // Monitor frame rate and adjust quality accordingly
        let displayLink = CADisplayLink(target: self, selector: #selector(monitorFrameRate))
        displayLink.add(to: .main, forMode: .common)
        
        // Store display link for cleanup
        self.performanceDisplayLink = displayLink
    }
    
    @objc private func monitorFrameRate() {
        // Simple frame rate monitoring
        frameCount += 1
        let currentTime = CACurrentMediaTime()
        
        if currentTime - lastFrameTime >= 1.0 {
            let fps = Double(frameCount) / (currentTime - lastFrameTime)
            
            // Adjust quality based on performance
            if fps < 30 && sceneView.antialiasingMode != .none {
                // Reduce quality if performance is poor
                sceneView.antialiasingMode = .none
                print("Reduced antialiasing due to low FPS: \(fps)")
            } else if fps > 50 && sceneView.antialiasingMode == .none {
                // Increase quality if performance allows
                sceneView.antialiasingMode = .multisampling2X
                print("Increased antialiasing due to good FPS: \(fps)")
            }
            
            frameCount = 0
            lastFrameTime = currentTime
        }
    }
    
    // MARK: - Performance Monitoring Properties
    
    private var performanceDisplayLink: CADisplayLink?
    private var frameCount: Int = 0
    private var lastFrameTime: TimeInterval = CACurrentMediaTime()
    
    func stopPerformanceMonitoring() {
        performanceDisplayLink?.invalidate()
        performanceDisplayLink = nil
    }
}

// MARK: - SCNNode Extension for Cleanup

extension SCNNode {
    func cleanup() {
        // Remove all animations
        removeAllAnimations()
        
        // Clean up geometry
        geometry?.materials.forEach { material in
            material.diffuse.contents = nil
            material.normal.contents = nil
            material.specular.contents = nil
        }
        
        // Recursively clean up child nodes
        childNodes.forEach { $0.cleanup() }
    }
}

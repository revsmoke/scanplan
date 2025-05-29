extension ResultsViewController {
    // MARK: - SceneKit Helper Methods
    
    /// Creates a standard base scene with correct configuration
    private func createBaseScene() -> SCNScene {
        return SCNScene()
    }
    
    /// Sets up a camera for the given scene
    /// - Parameters:
    ///   - scene: The scene to add the camera to
    ///   - isOverview: If true, positions camera for room overview; if false, positions for text viewing
    private func setupSceneCamera(for scene: SCNScene, isOverview: Bool = true) {
        let camera = SCNCamera()
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        
        if isOverview {
            // Position for room overview (looking down at 45 degrees)
            cameraNode.position = SCNVector3(x: 0, y: 5, z: 5)
            cameraNode.eulerAngles = SCNVector3(-Float.pi/4, 0, 0)
        } else {
            // Position for text viewing (front view)
            cameraNode.position = SCNVector3(0, 0, 5)
        }
        
        scene.rootNode.addChildNode(cameraNode)
    }
    
    /// Sets up standard lighting for the given scene
    /// - Parameter scene: The scene to add lighting to
    private func setupSceneLighting(for scene: SCNScene) {
        // Add ambient light
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.intensity = 200
        let ambientLightNode = SCNNode()
        ambientLightNode.light = ambientLight
        scene.rootNode.addChildNode(ambientLightNode)
        
        // Add directional light
        let directionalLight = SCNLight()
        directionalLight.type = .directional
        directionalLight.intensity = 800
        let directionalLightNode = SCNNode()
        directionalLightNode.light = directionalLight
        directionalLightNode.position = SCNVector3(x: 5, y: 5, z: 5)
        directionalLightNode.eulerAngles = SCNVector3(-Float.pi/4, Float.pi/4, 0)
        scene.rootNode.addChildNode(directionalLightNode)
    }
    
    /// Creates and configures a material with the given color and alpha
    /// - Parameters:
    ///   - color: The diffuse color for the material
    ///   - alpha: The opacity of the material (0.0-1.0)
    /// - Returns: The configured SCNMaterial
    private func createMaterial(color: UIColor, alpha: CGFloat = 1.0) -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = color.withAlphaComponent(alpha)
        return material
    }
    
    /// Creates a geometry node with the specified dimensions and material
    /// - Parameters:
    ///   - width: Width of the geometry
    ///   - height: Height of the geometry
    ///   - length: Length/depth of the geometry
    ///   - color: Color for the geometry material
    ///   - alpha: Opacity level for the material
    ///   - chamferRadius: Radius for rounded corners (0 for sharp corners)
    /// - Returns: A configured SCNNode with the geometry
    private func createGeometryNode(width: CGFloat, height: CGFloat, length: CGFloat, 
                                  color: UIColor, alpha: CGFloat = 1.0,
                                  chamferRadius: CGFloat = 0) -> SCNNode {
        let geometry = SCNBox(width: width, height: height, length: length, chamferRadius: chamferRadius)
        let material = createMaterial(color: color, alpha: alpha)
        geometry.materials = [material]
        return SCNNode(geometry: geometry)
    }
    
    /// Creates a floor node for the room
    /// - Parameters:
    ///   - width: Width of the floor
    ///   - length: Length of the floor
    /// - Returns: A configured floor node
    private func createFloorNode(width: Float, length: Float) -> SCNNode {
        let floorNode = createGeometryNode(
            width: CGFloat(width),
            height: 0.02,
            length: CGFloat(length),
            color: .systemGray6
        )
        floorNode.position = SCNVector3(x: 0, y: 0, z: 0)
        return floorNode
    }
    
    /// Creates a wall node with the provided dimensions and transform
    /// - Parameters:
    ///   - width: Width of the wall
    ///   - height: Height of the wall
    ///   - transform: Transform matrix for positioning
    /// - Returns: A configured wall node
    private func createWallNode(width: Float, height: Float, transform: simd_float4x4) -> SCNNode {
        let wallNode = createGeometryNode(
            width: CGFloat(width),
            height: CGFloat(height),
            length: 0.1,
            color: .systemBlue,
            alpha: 0.5
        )
        applyTransform(to: wallNode, transform: transform)
        return wallNode
    }
    
    /// Creates a room object node based on its category and dimensions
    /// - Parameters:
    ///   - category: The object category (door, window, furniture, etc.)
    ///   - width: Width of the object
    ///   - height: Height of the object
    ///   - length: Length of the object
    ///   - transform: Transform matrix for positioning
    /// - Returns: A configured object node
    private func createRoomObjectNode(category: CapturedRoom.Object.Category,
                                    width: Float, height: Float, length: Float,
                                    transform: simd_float4x4) -> SCNNode {
        let color: UIColor
        let objectLength: CGFloat
        let chamferRadius: CGFloat
        
        // Determine color and geometry based on category string to handle API changes
        let categoryString = getCategoryName(category)
        if categoryString == "Door" {
            color = .systemGreen
            objectLength = 0.1
            chamferRadius = 0
        } else if categoryString == "Window" {
            color = .systemCyan
            objectLength = 0.1
            chamferRadius = 0
        } else {
            color = .systemPurple
            objectLength = CGFloat(length)
            chamferRadius = 0.02
        }
        
        let node = createGeometryNode(
            width: CGFloat(width),
            height: CGFloat(height),
            length: objectLength,
            color: color,
            alpha: 0.7,
            chamferRadius: chamferRadius
        )
        
        applyTransform(to: node, transform: transform)
        return node
    }
    
    /// Applies a transform matrix to position and rotate a node
    /// - Parameters:
    ///   - node: The node to transform
    ///   - transform: The simd_float4x4 transform matrix to apply
    private func applyTransform(to node: SCNNode, transform: simd_float4x4) {
        // Get position from transform
        let position = getPositionFromTransform(transform)
        node.position = SCNVector3(position.x, position.y / 2, position.z) // Center height
        
        // Apply rotation from transform
        let rotation = getRotationYFromTransform(transform)
        node.eulerAngles = SCNVector3(0, rotation, 0)
    }
    // MARK: - Floor Plan Scene Creation
    
    private func createFloorPlanScene() {
        guard let roomData = finalRoomData else { return }
        
        // Create new scene with standard setup
        let scene = createBaseScene()
        setupSceneCamera(for: scene)
        setupSceneLighting(for: scene)
        
        // Add floor
        let floorNode = createFloorNode(width: roomWidth, length: roomLength)
        scene.rootNode.addChildNode(floorNode)
        
        // Count objects for accessibility info
        var wallCount = 0
        var doorCount = 0
        var windowCount = 0
        var furnitureCount = 0
        
        // Add walls
        for wall in roomData.walls {
            // Access the dimensions components directly
            let dimensions = wall.dimensions
            
            let wallNode = createWallNode(
                width: dimensions.x,  // x = width
                height: dimensions.y, // y = height
                transform: wall.transform
            )
            
            scene.rootNode.addChildNode(wallNode)
            wallCount += 1
        }
        
        // Process objects (doors, windows, furniture)
        for object in roomData.objects {
            // Access the dimensions components directly
            let dimensions = object.dimensions
            
            let objectNode = createRoomObjectNode(
                category: object.category,
                width: dimensions.x,   // x = width
                height: dimensions.y,  // y = height
                length: dimensions.z,  // z = length
                transform: object.transform
            )
            
            scene.rootNode.addChildNode(objectNode)
            
            // Count by category for accessibility
            let categoryString = getCategoryName(object.category)
            if categoryString == "Door" {
                doorCount += 1
            } else if categoryString == "Window" {
                windowCount += 1
            } else {
                furnitureCount += 1
            }
        }
        
        // Set the scene to the view
        sceneView.scene = scene
        
        // Update accessibility information for the scene
        let objectSummary = "Floor plan with \(wallCount) walls, \(doorCount) doors, \(windowCount) windows, and \(furnitureCount) furniture items"
        sceneView.accessibilityLabel = objectSummary
        
        // Post notification when scene is ready to ensure VoiceOver users know content has changed
        if UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(notification: .layoutChanged, argument: sceneView)
        }
    }
    
    // Helper functions for transforms
    private func getPositionFromTransform(_ transform: simd_float4x4) -> SIMD3<Float> {
        return SIMD3<Float>(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
    }
    
    private func getRotationYFromTransform(_ transform: simd_float4x4) -> Float {
        return atan2(transform.columns.0.z, transform.columns.0.x)
    }
}

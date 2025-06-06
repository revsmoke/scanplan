import UIKit
import SceneKit

extension ResultsViewController {
    // MARK: - SceneKit Helper Methods

    /// Creates a standard base scene with correct configuration
    private func createBaseScene() -> SCNScene {
        let scene = SCNScene()
        scene.background.contents = UIColor.systemBackground

        // Apply performance optimizations
        optimizeSceneForPerformance(scene)

        return scene
    }

    /// Sets up a camera for the given scene
    /// - Parameters:
    ///   - scene: The scene to add the camera to
    ///   - isOverview: If true, positions camera for room overview; if false, positions for text viewing
    func setupSceneCamera(for scene: SCNScene, isOverview: Bool = true) {
        let camera = SCNCamera()
        let cameraNode = SCNNode()
        cameraNode.camera = camera

        if isOverview {
            cameraNode.position = SCNVector3(x: 0, y: 5, z: 5)
            cameraNode.eulerAngles = SCNVector3(-Float.pi/4, 0, 0)
        } else {
            cameraNode.position = SCNVector3(0, 0, 5)
        }

        scene.rootNode.addChildNode(cameraNode)
    }

    /// Sets up standard lighting for the given scene
    /// - Parameter scene: The scene to add lighting to
    func setupSceneLighting(for scene: SCNScene) {
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.intensity = 200
        let ambientLightNode = SCNNode()
        ambientLightNode.light = ambientLight
        scene.rootNode.addChildNode(ambientLightNode)

        let directionalLight = SCNLight()
        directionalLight.type = .directional
        directionalLight.intensity = 800
        let directionalLightNode = SCNNode()
        directionalLightNode.light = directionalLight
        directionalLightNode.position = SCNVector3(x: 5, y: 5, z: 5)
        directionalLightNode.eulerAngles = SCNVector3(-Float.pi/4, Float.pi/4, 0)
        scene.rootNode.addChildNode(directionalLightNode)
    }

    func createMaterial(color: UIColor, alpha: CGFloat = 1.0) -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = color.withAlphaComponent(alpha)
        return material
    }

    func createGeometryNode(width: CGFloat, height: CGFloat, length: CGFloat,
                            color: UIColor, alpha: CGFloat = 1.0,
                            chamferRadius: CGFloat = 0) -> SCNNode {
        let geometry = SCNBox(width: width, height: height, length: length, chamferRadius: chamferRadius)
        let material = createMaterial(color: color, alpha: alpha)
        geometry.materials = [material]
        return SCNNode(geometry: geometry)
    }

    func createFloorNode(width: Float, length: Float) -> SCNNode {
        let floorNode = createGeometryNode(
            width: CGFloat(width),
            height: 0.02,
            length: CGFloat(length),
            color: .systemGray6
        )
        floorNode.position = SCNVector3(x: 0, y: 0, z: 0)
        return floorNode
    }

    func createWallNode(width: Float, height: Float, transform: simd_float4x4) -> SCNNode {
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

    func createRoomObjectNode(category: CapturedRoom.Object.Category,
                              width: Float, height: Float, length: Float,
                              transform: simd_float4x4) -> SCNNode {
        let color: UIColor
        let objectLength: CGFloat
        let chamferRadius: CGFloat

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

    func applyTransform(to node: SCNNode, transform: simd_float4x4) {
        let position = getPositionFromTransform(transform)
        node.position = SCNVector3(position.x, position.y / 2, position.z)

        let rotation = getRotationYFromTransform(transform)
        node.eulerAngles = SCNVector3(0, rotation, 0)
    }

    func getPositionFromTransform(_ transform: simd_float4x4) -> SIMD3<Float> {
        SIMD3<Float>(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
    }

    func getRotationYFromTransform(_ transform: simd_float4x4) -> Float {
        atan2(transform.columns.0.z, transform.columns.0.x)
    }

    // MARK: - Floor Plan Scene Creation

    func createFloorPlanScene() {
        guard let roomData = finalRoomData else { return }

        let scene = createBaseScene()
        setupSceneCamera(for: scene)
        setupSceneLighting(for: scene)

        let floorNode = createFloorNode(width: roomWidth, length: roomLength)
        scene.rootNode.addChildNode(floorNode)

        var wallCount = 0
        var doorCount = 0
        var windowCount = 0
        var furnitureCount = 0

        for wall in roomData.walls {
            let dimensions = wall.dimensions
            let wallNode = createWallNode(
                width: dimensions.x,
                height: dimensions.y,
                transform: wall.transform
            )
            scene.rootNode.addChildNode(wallNode)
            wallCount += 1
        }

        for object in roomData.objects {
            let dimensions = object.dimensions
            let objectNode = createRoomObjectNode(
                category: object.category,
                width: dimensions.x,
                height: dimensions.y,
                length: dimensions.z,
                transform: object.transform
            )
            scene.rootNode.addChildNode(objectNode)

            let categoryString = getCategoryName(object.category)
            if categoryString == "Door" {
                doorCount += 1
            } else if categoryString == "Window" {
                windowCount += 1
            } else {
                furnitureCount += 1
            }
        }

        sceneView.scene = scene

        let objectSummary = "Floor plan with \(wallCount) walls, \(doorCount) doors, \(windowCount) windows, and \(furnitureCount) furniture items"
        sceneView.accessibilityLabel = objectSummary

        if UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(notification: .layoutChanged, argument: sceneView)
        }
    }

    // MARK: - Empty Scene

    func setupEmptyScene() {
        let scene = createBaseScene()
        let textNode = createTextNode(text: "No room data available")
        textNode.position = SCNVector3(0, 0, 0)
        scene.rootNode.addChildNode(textNode)
        setupSceneCamera(for: scene, isOverview: false)
        sceneView.scene = scene
        sceneView.backgroundColor = .systemGray6
        sceneView.accessibilityLabel = "3D view: No room data available"
    }

    func createTextNode(text: String) -> SCNNode {
        let textGeometry = SCNText(string: text, extrusionDepth: 0)
        textGeometry.font = UIFont.systemFont(ofSize: 0.5)
        textGeometry.flatness = 0.1

        let textNode = SCNNode(geometry: textGeometry)
        textGeometry.alignmentMode = CATextLayerAlignmentMode.center.rawValue
        textNode.pivot = SCNMatrix4MakeTranslation(
            Float(textGeometry.boundingBox.max.x - textGeometry.boundingBox.min.x) / 2,
            Float(textGeometry.boundingBox.max.y - textGeometry.boundingBox.min.y) / 2,
            0
        )

        let material = SCNMaterial()
        material.diffuse.contents = UIColor.darkGray
        textGeometry.materials = [material]

        return textNode
    }
}

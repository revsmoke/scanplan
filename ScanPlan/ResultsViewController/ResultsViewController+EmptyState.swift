extension ResultsViewController {
    
    // MARK: - Handling Empty States
    
    private func updateEmptyState() {
        // Update dimensions with placeholder text
        guard let widthLabel = dimensionsStackView.arrangedSubviews[0].subviews.last as? UILabel,
              let lengthLabel = dimensionsStackView.arrangedSubviews[1].subviews.last as? UILabel,
              let heightLabel = dimensionsStackView.arrangedSubviews[2].subviews.last as? UILabel,
              let areaLabel = dimensionsStackView.arrangedSubviews[3].subviews.last as? UILabel else {
            return
        }
        
        widthLabel.text = "- -"
        lengthLabel.text = "- -"
        heightLabel.text = "- -"
        areaLabel.text = "- -"
        
        // Add empty state to scene view
        setupEmptyScene()
        
        // Clear table view
        measurements = []
        tableView.reloadData()
        
        // Update accessibility for dimension cards in empty state
        for (index, view) in dimensionsStackView.arrangedSubviews.enumerated() {
            let title: String
            switch index {
            case 0: title = "Width"
            case 1: title = "Length"
            case 2: title = "Height"
            case 3: title = "Area"
            default: title = "Dimension"
            }
            
            view.accessibilityLabel = "\(title): not available"
        }
        
        // Announce to user that no data is available
        UIAccessibility.post(notification: .screenChanged, argument: "No room data available")
    }
    
    private func setupEmptyScene() {
        // Create empty scene with message
        let scene = createBaseScene()
        
        // Add text node
        let textNode = createTextNode(text: "No room data available")
        textNode.position = SCNVector3(0, 0, 0)
        scene.rootNode.addChildNode(textNode)
        
        // Set camera for empty scene - use front-facing camera (not overview)
        setupSceneCamera(for: scene, isOverview: false)
        
        sceneView.scene = scene
        sceneView.backgroundColor = .systemGray6
        
        // Update accessibility for empty scene
        sceneView.accessibilityLabel = "3D view: No room data available"
    }
    
    private func createTextNode(text: String) -> SCNNode {
        let textGeometry = SCNText(string: text, extrusionDepth: 0)
        textGeometry.font = UIFont.systemFont(ofSize: 0.5)
        textGeometry.flatness = 0.1
        
        let textNode = SCNNode(geometry: textGeometry)
        
        // Center the text
        textGeometry.alignmentMode = CATextLayerAlignmentMode.center.rawValue
        textNode.pivot = SCNMatrix4MakeTranslation(Float(textGeometry.boundingBox.max.x - textGeometry.boundingBox.min.x) / 2,
                                                 Float(textGeometry.boundingBox.max.y - textGeometry.boundingBox.min.y) / 2,
                                                 0)
        
        // Apply material
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.darkGray
        textGeometry.materials = [material]
        
        return textNode
    }
    
    // MARK: - Memory Management
    
    deinit {
        // Clean up any temporary files when this controller is deallocated
        cleanupTemporaryFiles()
    }
    
    private func cleanupTemporaryFiles() {
        // Clean up model URL
        if let modelURL = temporaryModelURL, FileManager.default.fileExists(atPath: modelURL.path) {
            try? FileManager.default.removeItem(at: modelURL)
            temporaryModelURL = nil
        }
        
        // Clean up model directory
        let modelDirectory = FileManager.default.temporaryDirectory.appending(path: "RoomModel")
        if FileManager.default.fileExists(atPath: modelDirectory.path) {
            try? FileManager.default.removeItem(at: modelDirectory)
        }
        
        // Clean up export directory
        let exportDirectory = FileManager.default.temporaryDirectory.appending(path: "Export")
        if FileManager.default.fileExists(atPath: exportDirectory.path) {
            try? FileManager.default.removeItem(at: exportDirectory)
        }
        
        print("Temporary files cleaned up")
    }
}
}

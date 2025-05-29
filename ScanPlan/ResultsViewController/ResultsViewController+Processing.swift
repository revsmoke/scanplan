extension ResultsViewController {
    // MARK: - Data Processing
    
    private func processRoomData() {
        guard let roomData = finalRoomData else {
            showAlert(title: "Missing Data", message: "No room data available to process")
            
            // Disable interactive elements that depend on room data
            viewModelButton.isEnabled = false
            exportButton.isEnabled = false
            
            // Update UI with empty state
            updateEmptyState()
            return
        }
        
        // Extract overall room dimensions - estimated from the data
        var maxX: Float = 0
        var maxY: Float = 0
        var maxZ: Float = 0
        
        // Process walls
        var wallItems: [MeasurementItem] = []
        
        for (index, wall) in roomData.walls.enumerated() {
            // Get dimensions from the wall
            // Access the dimensions components directly
            let dimensions = wall.dimensions
            // Use x as width and y as height for simd_float3
            let width = dimensions.x
            let height = dimensions.y
            
            // Track maximum dimensions
            maxX = max(maxX, width)
            maxY = max(maxY, height)
            
            // Add to wall items
            wallItems.append(MeasurementItem(
                name: "Wall \(index + 1)",
                width: width,
                height: height,
                length: 0.1 // Walls are thin
            ))
        }
        
        // Process doors, windows, and furniture
        var doorItems: [MeasurementItem] = []
        var windowItems: [MeasurementItem] = []
        var furnitureItems: [MeasurementItem] = []
        
        for (index, object) in roomData.objects.enumerated() {
            // Access the dimensions components directly
            let dimensions = object.dimensions
            // Use x as width, y as height, and z as length for simd_float3
            let width = dimensions.x
            let height = dimensions.y
            let length = dimensions.z
            
            // Track maximum dimensions
            maxX = max(maxX, width)
            maxZ = max(maxZ, length)
            
            // Create measurement item
            let item = MeasurementItem(
                name: "\(getCategoryName(object.category)) \(index + 1)",
                width: width,
                height: height,
                length: length
            )
            
            // Categorize by object type using the string name
            let categoryString = getCategoryName(object.category)
            if categoryString == "Door" {
                doorItems.append(item)
            } else if categoryString == "Window" {
                windowItems.append(item)
            } else {
                furnitureItems.append(item)
            }
        }
        
        // Set room dimensions
        roomWidth = maxX
        roomLength = maxZ
        roomHeight = maxY
        roomArea = roomWidth * roomLength
        
        // Update measurement sections
        measurements = []
        
        if !wallItems.isEmpty {
            measurements.append(("Walls", wallItems))
        }
        
        if !doorItems.isEmpty {
            measurements.append(("Doors", doorItems))
        }
        
        if !windowItems.isEmpty {
            measurements.append(("Windows", windowItems))
        }
        
        if !furnitureItems.isEmpty {
            measurements.append(("Furniture", furnitureItems))
        }
        
        // Update UI
        updateDimensionsDisplay()
        tableView.reloadData()
        
        // Create 3D visualization
        createFloorPlanScene()
    }
    
    private func getCategoryName(_ category: CapturedRoom.Object.Category) -> String {
        // Use string description of the enum to handle API changes in iOS 18
        let categoryString = String(describing: category)
        
        // Map enum description to friendly names
        switch categoryString {
        case _ where categoryString.contains("door"):
            return "Door"
        case _ where categoryString.contains("window"):
            return "Window"
        case _ where categoryString.contains("bathtub"):
            return "Bathtub"
        case _ where categoryString.contains("bed"):
            return "Bed"
        case _ where categoryString.contains("chair"):
            return "Chair"
        case _ where categoryString.contains("dishwasher"):
            return "Dishwasher"
        case _ where categoryString.contains("fireplace"):
            return "Fireplace"
        case _ where categoryString.contains("oven"):
            return "Oven"
        case _ where categoryString.contains("refrigerator"):
            return "Refrigerator"
        case _ where categoryString.contains("sink"):
            return "Sink"
        case _ where categoryString.contains("sofa"):
            return "Sofa"
        case _ where categoryString.contains("stairs"):
            return "Stairs"
        case _ where categoryString.contains("storage"):
            return "Storage"
        case _ where categoryString.contains("stove"):
            return "Stove"
        case _ where categoryString.contains("table"):
            return "Table"
        case _ where categoryString.contains("television"):
            return "TV"
        case _ where categoryString.contains("toilet"):
            return "Toilet"
        case _ where categoryString.contains("washerDryer"):
            return "Washer/Dryer"
        default:
            return "Unknown"
        }
    }
    
    // Helper to update all dimension displays when unit system changes
    private func updateDimensionsDisplay() {
        // Update the UI with current dimensions in the selected unit system
        guard let widthLabel = dimensionsStackView.arrangedSubviews[0].subviews.last as? UILabel,
              let lengthLabel = dimensionsStackView.arrangedSubviews[1].subviews.last as? UILabel,
              let heightLabel = dimensionsStackView.arrangedSubviews[2].subviews.last as? UILabel,
              let areaLabel = dimensionsStackView.arrangedSubviews[3].subviews.last as? UILabel else {
            return
        }
        
        if isMetric {
            // Metric measurements
            widthLabel.text = String(format: "%.2f m", roomWidth)
            lengthLabel.text = String(format: "%.2f m", roomLength)
            heightLabel.text = String(format: "%.2f m", roomHeight)
            areaLabel.text = String(format: "%.2f m²", roomArea)
        } else {
            // Imperial measurements
            let feetPerMeter: Float = 3.28084
            widthLabel.text = String(format: "%.2f ft", roomWidth * feetPerMeter)
            lengthLabel.text = String(format: "%.2f ft", roomLength * feetPerMeter)
            heightLabel.text = String(format: "%.2f ft", roomHeight * feetPerMeter)
            areaLabel.text = String(format: "%.2f sq ft", roomArea * feetPerMeter * feetPerMeter)
        }
        
        // Refresh table view to update measurements
        tableView.reloadData()
    }
    
}

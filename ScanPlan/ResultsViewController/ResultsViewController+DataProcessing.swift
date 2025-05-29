import UIKit
import RoomPlan

extension ResultsViewController {
    // MARK: - Data Processing

    func processRoomData() {
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
            let dimensions = wall.dimensions
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
            let dimensions = object.dimensions
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

        updateDimensionsDisplay()
        tableView.reloadData()

        createFloorPlanScene()
    }

    func getCategoryName(_ category: CapturedRoom.Object.Category) -> String {
        let categoryString = String(describing: category)

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

    func updateDimensionsDisplay() {
        guard let widthLabel = dimensionsStackView.arrangedSubviews[0].subviews.last as? UILabel,
              let lengthLabel = dimensionsStackView.arrangedSubviews[1].subviews.last as? UILabel,
              let heightLabel = dimensionsStackView.arrangedSubviews[2].subviews.last as? UILabel,
              let areaLabel = dimensionsStackView.arrangedSubviews[3].subviews.last as? UILabel else {
            return
        }

        if isMetric {
            widthLabel.text = String(format: "%.2f m", roomWidth)
            lengthLabel.text = String(format: "%.2f m", roomLength)
            heightLabel.text = String(format: "%.2f m", roomHeight)
            areaLabel.text = String(format: "%.2f m²", roomArea)
        } else {
            let feetPerMeter: Float = 3.28084
            widthLabel.text = String(format: "%.2f ft", roomWidth * feetPerMeter)
            lengthLabel.text = String(format: "%.2f ft", roomLength * feetPerMeter)
            heightLabel.text = String(format: "%.2f ft", roomHeight * feetPerMeter)
            areaLabel.text = String(format: "%.2f sq ft", roomArea * feetPerMeter * feetPerMeter)
        }

        tableView.reloadData()
    }

    func updateEmptyState() {
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

        setupEmptyScene()

        measurements = []
        tableView.reloadData()

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

        UIAccessibility.post(notification: .screenChanged, argument: "No room data available")
    }
}

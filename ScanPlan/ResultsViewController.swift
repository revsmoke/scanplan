import UIKit
import RoomPlan
import SceneKit
import QuickLook

class ResultsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
    
    // UI Components
    private var scrollView: UIScrollView!
    private var contentView: UIView!
    private var roomInfoView: UIView!
    private var dimensionsStackView: UIStackView!
    private var tableView: UITableView!
    private var segmentedControl: UISegmentedControl!
    private var sceneView: SCNView!
    
    // Buttons
    private var exportButton: UIButton!
    private var viewModelButton: UIButton!
    
    // Activity indicator
    private var activityIndicator: UIActivityIndicatorView?
    
    // The captured room data from RoomPlan
    var finalRoomData: CapturedRoom?
    
    // Temporary URL for the exported USDZ file
    private var temporaryModelURL: URL?
    
    // Container for stacked buttons at bottom
    private var buttonStackView: UIStackView!
    
    // Measurement data
    private var roomWidth: Float = 0
    private var roomLength: Float = 0
    private var roomHeight: Float = 0
    private var roomArea: Float = 0
    
    // Data for the table view
    private var measurements: [(title: String, items: [MeasurementItem])] = []
    
    // Simple data structure for measurements
    struct MeasurementItem {
        let name: String
        let width: Float
        let height: Float
        let length: Float
    }
    
    // Current unit system (persisted with UserDefaults)
    private var isMetric: Bool = {
        // Load saved preference or default to true (metric)
        return UserDefaults.standard.object(forKey: "RoomPlanUseMetricUnits") as? Bool ?? true
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup the UI layout
        setupUI()
        
        // Process room data
        processRoomData()
        
        // Generate the 3D model right away
        generateModel()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Nothing special needed here now
    }
    
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
    
    // MARK: - UI Setup
    private func setupUI() {
        // Configure navigation bar
        title = "Room Plan Results"
        
        // Add a "Continue Scanning" button to the navigation bar
        let scanButton = UIBarButtonItem(
            title: "Continue Scanning",
            style: .plain,
            target: self,
            action: #selector(continueScanningTapped)
        )
        navigationItem.rightBarButtonItem = scanButton
        
        // Setup scrollview for the content
        setupScrollView()
        
        // Setup room info card with dimensions
        setupRoomInfoView()
        
        // Setup segmented control for unit switching
        setupUnitSegmentedControl()
        
        // Setup 2D floor plan view
        setupFloorPlanView()
        
        // Setup table view for walls and objects
        setupTableView()
        
        // Setup buttons at the bottom
        setupButtonStackView()
        
        // Add activity indicator
        setupActivityIndicator()
    }
    
    private func setupScrollView() {
        // Create scroll view with Auto Layout
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .systemGroupedBackground
        view.addSubview(scrollView)
        
        // Pin scrollView to view edges (accounting for button stack at bottom)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -120) // Space for buttons
        ])
        
        // Create content view for the scroll view
        contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Pin contentView to scrollView edges with equal width
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    private func setupRoomInfoView() {
        // Card for room dimensions with Auto Layout
        roomInfoView = UIView()
        roomInfoView.translatesAutoresizingMaskIntoConstraints = false
        roomInfoView.backgroundColor = .systemBackground
        roomInfoView.layer.cornerRadius = 12
        roomInfoView.layer.shadowColor = UIColor.black.cgColor
        roomInfoView.layer.shadowOffset = CGSize(width: 0, height: 2)
        roomInfoView.layer.shadowRadius = 4
        roomInfoView.layer.shadowOpacity = 0.1
        contentView.addSubview(roomInfoView)
        
        // Position roomInfoView with constraints
        NSLayoutConstraint.activate([
            roomInfoView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            roomInfoView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            roomInfoView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            roomInfoView.heightAnchor.constraint(equalToConstant: 160)
        ])
        
        // Add title with Auto Layout
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Room Dimensions"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        roomInfoView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: roomInfoView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: roomInfoView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: roomInfoView.trailingAnchor, constant: -16)
        ])
        
        // Create stack view for dimensions with Auto Layout
        dimensionsStackView = UIStackView()
        dimensionsStackView.translatesAutoresizingMaskIntoConstraints = false
        dimensionsStackView.axis = .horizontal
        dimensionsStackView.distribution = .fillEqually
        dimensionsStackView.spacing = 10
        roomInfoView.addSubview(dimensionsStackView)
        
        NSLayoutConstraint.activate([
            dimensionsStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            dimensionsStackView.leadingAnchor.constraint(equalTo: roomInfoView.leadingAnchor, constant: 16),
            dimensionsStackView.trailingAnchor.constraint(equalTo: roomInfoView.trailingAnchor, constant: -16),
            dimensionsStackView.bottomAnchor.constraint(equalTo: roomInfoView.bottomAnchor, constant: -16)
        ])
        
        // Add dimension items
        let dimensions = [
            ("Width", "0.00 m"),
            ("Length", "0.00 m"),
            ("Height", "0.00 m"),
            ("Area", "0.00 m²")
        ]
        
        for dimension in dimensions {
            let card = createDimensionCard(title: dimension.0, value: dimension.1)
            dimensionsStackView.addArrangedSubview(card)
        }
    }
    
    private func createDimensionCard(title: String, value: String) -> UIView {
        let card = UIView()
        card.backgroundColor = UIColor.systemGray6
        card.layer.cornerRadius = 8
        
        // Title label with Auto Layout
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = .secondaryLabel
        titleLabel.textAlignment = .center
        card.addSubview(titleLabel)
        
        // Value label with Auto Layout
        let valueLabel = UILabel()
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.text = value
        valueLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        valueLabel.textAlignment = .center
        card.addSubview(valueLabel)
        
        // Apply constraints
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            
            valueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            valueLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            valueLabel.bottomAnchor.constraint(lessThanOrEqualTo: card.bottomAnchor, constant: -8)
        ])
        
        // Add accessibility - make the whole card one accessible element
        card.isAccessibilityElement = true
        card.accessibilityLabel = "\(title): \(value)"
        card.accessibilityTraits = .staticText
        
        return card
    }
    
    private func setupUnitSegmentedControl() {
        // Create segmented control for unit switching with Auto Layout
        segmentedControl = UISegmentedControl(items: ["Metric", "Imperial"])
        segmentedControl.selectedSegmentIndex = isMetric ? 0 : 1 // Set based on saved preference
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(segmentedControl)
        
        // Position segmentedControl below roomInfoView
        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: roomInfoView.bottomAnchor, constant: 20),
            segmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            segmentedControl.heightAnchor.constraint(equalToConstant: 32)
        ])
        
        // Add action
        segmentedControl.addTarget(self, action: #selector(unitSystemChanged), for: .valueChanged)
        
        // Add accessibility
        segmentedControl.accessibilityLabel = "Measurement units"
        segmentedControl.accessibilityHint = "Switch between metric and imperial measurement units"
    }
    
    private func setupFloorPlanView() {
        // Setup 2D floor plan view using SceneKit with Auto Layout
        sceneView = SCNView()
        sceneView.translatesAutoresizingMaskIntoConstraints = false
        sceneView.backgroundColor = .systemBackground
        sceneView.layer.cornerRadius = 12
        sceneView.clipsToBounds = true
        sceneView.antialiasingMode = .multisampling4X
        contentView.addSubview(sceneView)
        
        // Position sceneView below segmentedControl
        NSLayoutConstraint.activate([
            sceneView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 20),
            sceneView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            sceneView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            sceneView.heightAnchor.constraint(equalToConstant: 300)
        ])
        
        // Set up initial empty scene using our helper methods
        let scene = createBaseScene()
        setupSceneCamera(for: scene)
        setupSceneLighting(for: scene)
        
        sceneView.scene = scene
        sceneView.allowsCameraControl = true
        
        // Add accessibility
        sceneView.isAccessibilityElement = true
        sceneView.accessibilityLabel = "3D floor plan view"
        sceneView.accessibilityHint = "Shows interactive visualization of room layout"
        sceneView.accessibilityTraits = .image
    }
    
    private func setupTableView() {
        // Setup table view for walls and objects with Auto Layout
        let frame = CGRect(x: 0, y: 0, width: contentView.bounds.width - 32, height: 400)
        tableView = UITableView(frame: frame, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.layer.cornerRadius = 12
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.isScrollEnabled = false // Prevent nested scrolling
        contentView.addSubview(tableView)
        
        // Position tableView below sceneView
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: sceneView.bottomAnchor, constant: 20),
            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupActivityIndicator() {
        // Add activity indicator with Auto Layout
        activityIndicator = UIActivityIndicatorView(style: .large)
        if let activityIndicator = activityIndicator {
            activityIndicator.translatesAutoresizingMaskIntoConstraints = false
            activityIndicator.hidesWhenStopped = true
            view.addSubview(activityIndicator)
            
            // Center activity indicator in view
            NSLayoutConstraint.activate([
                activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])
        }
    }
    
    private func setupButtonStackView() {
        // Create stack view for buttons with Auto Layout
        buttonStackView = UIStackView()
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        buttonStackView.axis = .vertical
        buttonStackView.spacing = 10
        buttonStackView.distribution = .fillEqually
        
        // Create "View 3D Model" button
        viewModelButton = createButton(title: "View 3D Model", color: .systemIndigo)
        viewModelButton.addTarget(self, action: #selector(viewModelButtonTapped), for: .touchUpInside)
        viewModelButton.isEnabled = false // Disabled until model is ready
        
        // Create export button
        exportButton = createButton(title: "Export Room Data", color: .systemBlue)
        exportButton.addTarget(self, action: #selector(exportButtonTapped), for: .touchUpInside)
        
        // Add buttons to stack
        buttonStackView.addArrangedSubview(viewModelButton)
        buttonStackView.addArrangedSubview(exportButton)
        
        // Add stack to view (not to the scroll view)
        view.addSubview(buttonStackView)
        
        // Position the button stack at the bottom of the screen
        NSLayoutConstraint.activate([
            buttonStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            buttonStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            buttonStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            buttonStackView.heightAnchor.constraint(equalToConstant: 110) // Height for two buttons
        ])
    }
    
    private func createButton(title: String, color: UIColor) -> UIButton {
        let button = UIButton(type: .system)
        button.backgroundColor = color
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        
        // Add shadow
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.layer.shadowOpacity = 0.1
        
        // Add accessibility
        button.accessibilityLabel = title
        
        if title.contains("3D Model") {
            button.accessibilityHint = "Opens interactive 3D model of captured room"
        } else if title.contains("Export") {
            button.accessibilityHint = "Saves room data as USDZ and JSON files"
        }
        
        return button
    }
    
    
    // MARK: - Actions
    
    @objc private func continueScanningTapped() {
        // Pop back to the RoomCaptureViewController
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func unitSystemChanged(_ sender: UISegmentedControl) {
        isMetric = sender.selectedSegmentIndex == 0
        
        // Save preference to UserDefaults
        UserDefaults.standard.set(isMetric, forKey: "RoomPlanUseMetricUnits")
        
        // Update the UI
        updateDimensionsDisplay()
        
        // Announce unit change to VoiceOver
        UIAccessibility.post(notification: .announcement, 
                             argument: isMetric ? "Switched to metric units" : "Switched to imperial units")
    }
    
    @objc private func viewModelButtonTapped() {
        // Present QuickLook preview of the 3D model
        let frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
        let previewController = QLPreviewController()
        previewController.view.frame = frame
        previewController.dataSource = self
        previewController.delegate = self
        present(previewController, animated: true)
    }
    
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
    
    
    // MARK: - Memory Management
    
    deinit {
        // Clean up any temporary files when this controller is deallocated
        cleanupTemporaryFiles()
    }
    
}

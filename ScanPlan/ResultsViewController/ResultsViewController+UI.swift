extension ResultsViewController {
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

        // Configure performance-optimized settings
        configureSceneViewPerformance()

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
    
}

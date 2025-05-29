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
    
    
    
    // MARK: - Memory Management
    
    deinit {
        // Clean up any temporary files when this controller is deallocated
        cleanupTemporaryFiles()
    }
}

import UIKit
import WebKit
import RoomPlan
import SceneKit
import ModelIO
import QuickLook

class ResultsViewController: UIViewController, WKScriptMessageHandler, WKNavigationDelegate, QLPreviewControllerDataSource {

    // A WKWebView to load your local HTML
    private var webView: WKWebView!
    
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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup UI elements
        setupUI()
        
        // 1) Configure the web view
        let config = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        // (Optional) If you want JavaScript -> Swift messages:
        userContentController.add(self, name: "iOSListener")
        config.userContentController = userContentController

        // Enable developer tools and JavaScript console logging
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")
        
        // Create webview with adjusted frame to make room for the button stack
        let webViewFrame = CGRect(x: 0, y: 0, 
                                 width: view.bounds.width, 
                                 height: view.bounds.height - 130) // Leave room for two buttons
        webView = WKWebView(frame: webViewFrame, configuration: config)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(webView)
        
        // Add a navigation delegate to detect load completion
        webView.navigationDelegate = self
        
        // 2) Load the local HTML file
        // Try different approaches to find the HTML file
        let fileManager = FileManager.default
        
        // Option 1: Try from bundle resources directly
        if let htmlURL = Bundle.main.url(forResource: "index", withExtension: "html") {
            print("Found HTML in bundle: \(htmlURL)")
            webView.loadFileURL(htmlURL, allowingReadAccessTo: htmlURL.deletingLastPathComponent())
            return
        }
        
        // Option 2: Look for the file in the bundle's resource path
        if let resourcePath = Bundle.main.resourcePath {
            let indexPath = resourcePath + "/index.html"
            
            if fileManager.fileExists(atPath: indexPath) {
                print("Found HTML using file manager at: \(indexPath)")
                let htmlURL = URL(fileURLWithPath: indexPath)
                webView.loadFileURL(htmlURL, allowingReadAccessTo: URL(fileURLWithPath: resourcePath))
                return
            }
        }
        
        // Option 3: Load directly from the project directory structure in development
        #if DEBUG
        let devPath = "/Applications/ColdFusion2023/cfusion/wwwroot/archinet/projects/spaceplanning/roomplan/RoomPlanExampleApp/index.html"
        if fileManager.fileExists(atPath: devPath) {
            print("Found HTML in development path")
            let htmlURL = URL(fileURLWithPath: devPath)
            let rootURL = URL(fileURLWithPath: "/Applications/ColdFusion2023/cfusion/wwwroot/archinet/projects/spaceplanning/roomplan/RoomPlanExampleApp")
            webView.loadFileURL(htmlURL, allowingReadAccessTo: rootURL)
            return
        }
        #endif
        
        // If all options failed, log detailed info for debugging
        print("ERROR: Could not find index.html file")
        if let resourcePath = Bundle.main.resourcePath {
            print("Bundle resource path: \(resourcePath)")
            do {
                let contents = try fileManager.contentsOfDirectory(atPath: resourcePath)
                print("Bundle contents: \(contents)")
            } catch {
                print("Error listing bundle contents: \(error)")
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Data will be sent when the web view finishes loading
    }
    
    // Implement WKNavigationDelegate method to know when the page is fully loaded
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("Web view finished loading - now sending data")
        
        // First test if JavaScript is working
        webView.evaluateJavaScript("testFunction()") { result, error in
            if let error = error {
                print("Error calling test function: \(error)")
            } else {
                print("Test function result: \(String(describing: result))")
                // Now send the actual data
                self.sendDataToWebView()
            }
        }
    }

    private func sendDataToWebView() {
        // Make sure we have valid room data
        guard let finalRoomData = finalRoomData else { 
            print("No room data available to send")
            return 
        }

        do {
            // Use the same encoder as in RoomCaptureViewController
            let jsonEncoder = JSONEncoder()
            // For consistency with the export function
            jsonEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            
            // Encode the CapturedRoom into JSON
            let jsonData = try jsonEncoder.encode(finalRoomData)
            
            // Debug: Print a sample of the JSON
            if let jsonSample = String(data: jsonData.prefix(200), encoding: .utf8) {
                print("JSON sample: \(jsonSample)...")
            }
            
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                // Escape special characters for a JavaScript string
                let escapedJson = jsonString
                    .replacingOccurrences(of: "\\", with: "\\\\")
                    .replacingOccurrences(of: "\"", with: "\\\"")
                    .replacingOccurrences(of: "\n", with: "\\n")

                // First check if displayData function exists to avoid the error
                let checkCode = "typeof displayData === 'function'"
                webView.evaluateJavaScript(checkCode) { result, error in
                    if let result = result as? Bool, result {
                        // Function exists, call it
                        print("Calling displayData with JSON of length: \(jsonString.count)")
                        let jsCode = "displayData(\"\(escapedJson)\")"
                        self.webView.evaluateJavaScript(jsCode) { result, error in
                            if let error = error {
                                print("Error calling displayData in JS: \(error)")
                                
                                // Try to get more detailed error information
                                self.webView.evaluateJavaScript("console.error('Last error in displayData:', window.lastDisplayDataError || 'No error details')") { _, _ in }
                            } else {
                                print("Successfully sent data to web view")
                            }
                        }
                    } else {
                        print("displayData function not found in the web page")
                        // Let's try to debug by logging what functions are available
                        self.webView.evaluateJavaScript("console.log('Available functions:', Object.keys(window).filter(k => typeof window[k] === 'function'))") { _, _ in }
                    }
                }
            }
        } catch {
            print("Error encoding finalRoomData: \(error)")
        }
    }

    // Handle messages from JS if you use window.webkit.messageHandlers.iOSListener.postMessage(...)
    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        if message.name == "iOSListener" {
            // Example: let data = message.body as? String
            // Do something in Swift if needed
        }
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        // Add title to nav bar
        title = "Room Plan Results"
        
        // Add activity indicator
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator?.center = view.center
        activityIndicator?.hidesWhenStopped = true
        if let activityIndicator = activityIndicator {
            view.addSubview(activityIndicator)
        }
        
        // Create button stack view
        setupButtonStackView()
        
        // When the view loads, generate the 3D model right away
        generateModel()
    }
    
    private func setupButtonStackView() {
        // Create stack view for buttons
        buttonStackView = UIStackView()
        buttonStackView.axis = .vertical
        buttonStackView.spacing = 10
        buttonStackView.distribution = .fillEqually
        
        // Configure stack view position
        let padding: CGFloat = 16
        let stackHeight: CGFloat = 110 // Height for two buttons
        let stackWidth = view.bounds.width - (padding * 2)
        let yPosition = view.bounds.height - stackHeight - padding - view.safeAreaInsets.bottom
        
        buttonStackView.frame = CGRect(x: padding, y: yPosition, width: stackWidth, height: stackHeight)
        buttonStackView.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        
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
        
        // Add stack to view
        view.addSubview(buttonStackView)
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
        
        return button
    }
    
    // MARK: - Actions
    @objc private func viewModelButtonTapped() {
        // Present QuickLook preview of the 3D model
        let previewController = QLPreviewController()
        previewController.dataSource = self
        present(previewController, animated: true)
    }
    
    @objc private func exportButtonTapped() {
        // Show activity indicator
        activityIndicator?.startAnimating()
        
        // Disable button during export
        exportButton.isEnabled = false
        
        // Perform the export
        exportResults()
    }
    
    // Export the USDZ and JSON data - mirrors RoomCaptureViewController's exportResults
    private func exportResults() {
        guard let roomData = finalRoomData else {
            showAlert(title: "Export Error", message: "No room data available to export")
            activityIndicator?.stopAnimating()
            exportButton.isEnabled = true
            return
        }
        
        let destinationFolderURL = FileManager.default.temporaryDirectory.appending(path: "Export")
        let destinationURL = destinationFolderURL.appending(path: "Room.usdz")
        let capturedRoomURL = destinationFolderURL.appending(path: "Room.json")
        
        do {
            try FileManager.default.createDirectory(at: destinationFolderURL, withIntermediateDirectories: true)
            
            // Export JSON
            let jsonEncoder = JSONEncoder()
            jsonEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let jsonData = try jsonEncoder.encode(roomData)
            try jsonData.write(to: capturedRoomURL)
            
            // Export USDZ
            try roomData.export(to: destinationURL, exportOptions: .parametric)
            
            // Show share sheet
            let activityVC = UIActivityViewController(activityItems: [destinationFolderURL], applicationActivities: nil)
            activityVC.modalPresentationStyle = .popover
            
            // Set completion handler to re-enable button
            activityVC.completionWithItemsHandler = { [weak self] _, _, _, _ in
                self?.activityIndicator?.stopAnimating()
                self?.exportButton.isEnabled = true
            }
            
            present(activityVC, animated: true, completion: nil)
            if let popOver = activityVC.popoverPresentationController {
                popOver.sourceView = self.exportButton
            }
        } catch {
            showAlert(title: "Export Failed", message: error.localizedDescription)
            print("Export error: \(error)")
            activityIndicator?.stopAnimating()
            exportButton.isEnabled = true
        }
    }
    
    // Generate the 3D model and save it to a temporary file
    private func generateModel() {
        guard let roomData = finalRoomData else {
            print("No room data available to generate model")
            return
        }
        
        // Show activity indicator while generating model
        activityIndicator?.startAnimating()
        
        // Create a temporary directory for the model
        let modelDirectory = FileManager.default.temporaryDirectory.appending(path: "RoomModel")
        let modelURL = modelDirectory.appending(path: "RoomPreview.usdz")
        
        do {
            // Create directory if it doesn't exist
            try FileManager.default.createDirectory(at: modelDirectory, withIntermediateDirectories: true)
            
            // Remove any existing file
            if FileManager.default.fileExists(atPath: modelURL.path) {
                try FileManager.default.removeItem(at: modelURL)
            }
            
            // Export the USDZ model
            try roomData.export(to: modelURL, exportOptions: .parametric)
            
            // Save the URL for the QuickLook preview
            self.temporaryModelURL = modelURL
            
            // Enable the view model button
            DispatchQueue.main.async {
                self.viewModelButton.isEnabled = true
                self.activityIndicator?.stopAnimating()
            }
            
            print("3D model generated successfully at: \(modelURL.path)")
        } catch {
            print("Error generating 3D model: \(error)")
            DispatchQueue.main.async {
                self.activityIndicator?.stopAnimating()
            }
        }
    }
    
    // MARK: - QLPreviewControllerDataSource
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return temporaryModelURL != nil ? 1 : 0
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        guard let modelURL = temporaryModelURL else {
            fatalError("Model URL not available")
        }
        
        return modelURL as QLPreviewItem
    }
    
    // Helper to show alerts
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

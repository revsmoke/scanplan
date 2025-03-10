/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The sample app's main view controller that manages the scanning process.
*/

import UIKit
import RoomPlan

class RoomCaptureViewController: UIViewController, RoomCaptureViewDelegate, RoomCaptureSessionDelegate {
    
    @IBOutlet var exportButton: UIButton?
    @IBOutlet var doneButton: UIBarButtonItem?
    @IBOutlet var cancelButton: UIBarButtonItem?
    @IBOutlet var activityIndicator: UIActivityIndicatorView?
    
    private var isScanning: Bool = false
    
    private var roomCaptureView: RoomCaptureView!
    private var roomCaptureSessionConfig: RoomCaptureSession.Configuration = RoomCaptureSession.Configuration()
    
    private var finalResults: CapturedRoom?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up after loading the view.
        setupRoomCaptureView()
        activityIndicator?.stopAnimating()
    }
    
    private func setupRoomCaptureView() {
        roomCaptureView = RoomCaptureView(frame: view.bounds)
        roomCaptureView.captureSession.delegate = self
        roomCaptureView.delegate = self
        
        view.insertSubview(roomCaptureView, at: 0)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startSession()
    }
    
    override func viewWillDisappear(_ flag: Bool) {
        super.viewWillDisappear(flag)
        stopSession()
    }
    
    private func startSession() {
        isScanning = true
        roomCaptureView?.captureSession.run(configuration: roomCaptureSessionConfig)
        setActiveNavBar()
    }
    
    private func stopSession() {
        isScanning = false
        roomCaptureView?.captureSession.stop()
        setCompleteNavBar()
    }
    
    // Decide to post-process and show the final results.
    func captureView(shouldPresent roomDataForProcessing: CapturedRoomData, error: Error?) -> Bool {
        return true
    }
    
    // Access the final post-processed results.
    func captureView(didPresent processedResult: CapturedRoom, error: Error?) {
        finalResults = processedResult
        
        // Ensure UI updates happen on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.exportButton?.isEnabled = true
            self.activityIndicator?.stopAnimating()
            
            // Show alert with options for the user
            let alert = UIAlertController(
                title: "Room Scan Complete",
                message: "Your room scan has been processed. What would you like to do next?",
                preferredStyle: .alert
            )
            
            // Option to view results
            alert.addAction(UIAlertAction(title: "View Results", style: .default) { [weak self] _ in
                // Navigate to results screen
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                if let resultsVC = storyboard.instantiateViewController(withIdentifier: "ResultsViewController")
                    as? ResultsViewController {
                    
                    // Pass the captured room data to ResultsViewController
                    resultsVC.finalRoomData = processedResult
                    
                    // Push it onto the navigation stack
                    self?.navigationController?.pushViewController(resultsVC, animated: true)
                }
            })
            
            // Option to continue scanning
            alert.addAction(UIAlertAction(title: "Continue Scanning", style: .default) { [weak self] _ in
                // Just keep the current view controller active
                self?.startSession()
            })
            
            // Present alert
            self.present(alert, animated: true)
        }
    }
    
    @IBAction func doneScanning(_ sender: UIBarButtonItem) {
        if isScanning { stopSession() } else { cancelScanning(sender) }
        self.exportButton?.isEnabled = false
        self.activityIndicator?.startAnimating()
    }

    @IBAction func cancelScanning(_ sender: UIBarButtonItem) {
        cleanupTemporaryFiles()
        navigationController?.dismiss(animated: true)
    }
    
    // Export the USDZ output by specifying the `.parametric` export option.
    // Alternatively, `.mesh` exports a nonparametric file and `.all`
    // exports both in a single USDZ.
    @IBAction func exportResults(_ sender: UIButton) {
        // Disable button and show activity indicator
        self.exportButton?.isEnabled = false
        self.activityIndicator?.startAnimating()
        
        guard let finalResults = self.finalResults else {
            showAlert(title: "Export Error", message: "No room data available to export")
            self.activityIndicator?.stopAnimating()
            self.exportButton?.isEnabled = true
            return
        }
        
        let destinationFolderURL = FileManager.default.temporaryDirectory.appending(path: "Export")
        let destinationURL = destinationFolderURL.appending(path: "Room.usdz")
        let capturedRoomURL = destinationFolderURL.appending(path: "Room.json")
        
        do {
            // Create directory for export files
            do {
                try FileManager.default.createDirectory(at: destinationFolderURL, withIntermediateDirectories: true)
            } catch {
                throw NSError(domain: "AppErrorDomain", code: 100, 
                             userInfo: [NSLocalizedDescriptionKey: "Failed to create export directory: \(error.localizedDescription)"])
            }
            
            // Export JSON with specific error handling
            do {
                let jsonEncoder = JSONEncoder()
                jsonEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let jsonData = try jsonEncoder.encode(finalResults)
                try jsonData.write(to: capturedRoomURL)
            } catch {
                throw NSError(domain: "AppErrorDomain", code: 101, 
                             userInfo: [NSLocalizedDescriptionKey: "Failed to generate JSON data: \(error.localizedDescription)"])
            }
            
            // Export USDZ with specific error handling
            do {
                try finalResults.export(to: destinationURL, exportOptions: .parametric)
            } catch {
                throw NSError(domain: "AppErrorDomain", code: 102, 
                             userInfo: [NSLocalizedDescriptionKey: "Failed to generate 3D model: \(error.localizedDescription)"])
            }
            
            // Show share sheet
            let activityVC = UIActivityViewController(activityItems: [destinationFolderURL], applicationActivities: nil)
            activityVC.modalPresentationStyle = .popover
            
            // Set completion handler to re-enable button
            activityVC.completionWithItemsHandler = { [weak self] _, _, _, _ in
                DispatchQueue.main.async {
                    self?.activityIndicator?.stopAnimating()
                    self?.exportButton?.isEnabled = true
                }
            }
            
            present(activityVC, animated: true, completion: nil)
            if let popOver = activityVC.popoverPresentationController {
                popOver.sourceView = self.exportButton
            }
        } catch {
            let errorMessage = (error as NSError).localizedDescription
            showAlert(title: "Export Failed", message: errorMessage)
            print("Export error: \(error)")
            
            DispatchQueue.main.async { [weak self] in
                self?.activityIndicator?.stopAnimating()
                self?.exportButton?.isEnabled = true
            }
        }
    }
    
    // Helper to show alerts
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func setActiveNavBar() {
        UIView.animate(withDuration: 1.0, animations: {
            self.cancelButton?.tintColor = .white
            self.doneButton?.tintColor = .white
            self.exportButton?.alpha = 0.0
        }, completion: { _ in
            self.exportButton?.isHidden = true
        })
    }
    
    private func setCompleteNavBar() {
        self.exportButton?.isHidden = false
        UIView.animate(withDuration: 1.0) {
            self.cancelButton?.tintColor = .systemBlue
            self.doneButton?.tintColor = .systemBlue
            self.exportButton?.alpha = 1.0
        }
    }
    
    // MARK: - Memory Management
    
    deinit {
        // Clean up any temporary files when this controller is deallocated
        cleanupTemporaryFiles()
    }
    
    private func cleanupTemporaryFiles() {
        // Clean up export directory
        let exportDirectory = FileManager.default.temporaryDirectory.appending(path: "Export")
        if FileManager.default.fileExists(atPath: exportDirectory.path) {
            try? FileManager.default.removeItem(at: exportDirectory)
        }
        
        print("Room capture temporary files cleaned up")
    }
}

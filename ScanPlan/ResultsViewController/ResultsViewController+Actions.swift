extension ResultsViewController {
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
    
    // MARK: - QLPreviewControllerDelegate
    
    func previewControllerDidDismiss(_ controller: QLPreviewController) {
        // We don't clean up model immediately after viewing
        // This allows user to view it multiple times
        // Model will be cleaned up when the controller is deallocated
    }
    
    @objc private func exportButtonTapped() {
        // Show activity indicator
        activityIndicator?.startAnimating()
        
        // Disable button during export
        exportButton.isEnabled = false
        
        // Perform the export
        exportResults()
    }
    
    // MARK: - QLPreviewControllerDataSource
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return temporaryModelURL != nil ? 1 : 0
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        guard let modelURL = temporaryModelURL else {
            // Create a fallback URL instead of crashing
            DispatchQueue.main.async { [weak self] in
                controller.dismiss(animated: true) { [weak self] in
                    DispatchQueue.main.async {
                        self?.showAlert(title: "3D Model Error", message: "The 3D model is not available or failed to generate.")
                    }
                }
            }
            // Return empty file URL as fallback
            return URL(fileURLWithPath: "") as QLPreviewItem
        }
        
        return modelURL as QLPreviewItem
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
                let jsonData = try jsonEncoder.encode(roomData)
                try jsonData.write(to: capturedRoomURL)
            } catch {
                throw NSError(domain: "AppErrorDomain", code: 101, 
                             userInfo: [NSLocalizedDescriptionKey: "Failed to generate JSON data: \(error.localizedDescription)"])
            }
            
            // Export USDZ with highest fidelity
            // `.all` preserves both the parametric data and underlying mesh
            // for accurate architectural reference.
            do {
                try roomData.export(to: destinationURL, exportOptions: .all)
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
                    self?.exportButton.isEnabled = true
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
                self?.exportButton.isEnabled = true
            }
        }
    }
    
    // Generate the 3D model and save it to a temporary file
    private func generateModel() {
        guard let roomData = finalRoomData else {
            showAlert(title: "Model Generation Failed", message: "No room data available to generate model")
            return
        }
        
        // Show activity indicator while generating model
        activityIndicator?.startAnimating()
        
        // Clean up any existing model first
        if let existingURL = temporaryModelURL, FileManager.default.fileExists(atPath: existingURL.path) {
            try? FileManager.default.removeItem(at: existingURL)
            temporaryModelURL = nil
        }
        
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
            
            // Export the USDZ model using `.all` for maximum detail
            try roomData.export(to: modelURL, exportOptions: .all)
            
            // Save the URL for the QuickLook preview - ensure on main thread
            DispatchQueue.main.async { [weak self] in
                self?.temporaryModelURL = modelURL
            }
            
            // Enable the view model button
            DispatchQueue.main.async {
                self.viewModelButton.isEnabled = true
                self.activityIndicator?.stopAnimating()
            }
            
            print("3D model generated successfully at: \(modelURL.path)")
        } catch {
            print("Error generating 3D model: \(error)")
            DispatchQueue.main.async { [weak self] in
                self?.activityIndicator?.stopAnimating()
                self?.viewModelButton.isEnabled = false
                self?.showAlert(title: "Model Generation Failed", 
                               message: "Failed to generate 3D model: \(error.localizedDescription)")
            }
        }
    }
    
    // Helper to show alerts
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

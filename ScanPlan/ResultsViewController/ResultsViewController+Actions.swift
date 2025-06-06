import UIKit
import QuickLook

extension ResultsViewController {
    // MARK: - Actions

    @objc func continueScanningTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc func unitSystemChanged(_ sender: UISegmentedControl) {
        isMetric = sender.selectedSegmentIndex == 0
        UserDefaults.standard.set(isMetric, forKey: "RoomPlanUseMetricUnits")
        updateDimensionsDisplay()
        UIAccessibility.post(notification: .announcement,
                             argument: isMetric ? "Switched to metric units" : "Switched to imperial units")
    }

    @objc private func viewModelButtonTapped() {
        // Present QuickLook preview of the 3D model
        let previewController = QLPreviewController()
        previewController.dataSource = self
        previewController.delegate = self
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

    // MARK: - QLPreviewControllerDelegate

    func previewControllerDidDismiss(_ controller: QLPreviewController) {
        // We don't clean up model immediately after viewing
        // This allows user to view it multiple times
        // Model will be cleaned up when the controller is deallocated
    }

    // MARK: - QLPreviewControllerDataSource

    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return temporaryModelURL != nil ? 1 : 0
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        guard let modelURL = temporaryModelURL else {
            // Return a proper error document instead of empty URL
            return createErrorPreviewItem()
        }
        return modelURL as QLPreviewItem
    }

    private func createErrorPreviewItem() -> QLPreviewItem {
        // Create a temporary text file with error message
        let errorURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("model_error.txt")

        let errorMessage = """
        3D Model Not Available

        The 3D model could not be generated or is not ready yet.

        Please try the following:
        1. Wait for the model generation to complete
        2. Tap "View 3D Model" again
        3. If the problem persists, try scanning the room again

        For best results, ensure good lighting and move slowly during scanning.
        """

        do {
            try errorMessage.write(to: errorURL, atomically: true, encoding: .utf8)
        } catch {
            print("Failed to create error preview file: \(error)")
        }

        return errorURL as QLPreviewItem
    }

    // Helper to show alerts
    private func showAlert(title: String, message: String, actions: [UIAlertAction] = []) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        if actions.isEmpty {
            alert.addAction(UIAlertAction(title: "OK", style: .default))
        } else {
            actions.forEach { alert.addAction($0) }
        }

        present(alert, animated: true)
    }
}

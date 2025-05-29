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

    @objc func viewModelButtonTapped() {
        let frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
        let previewController = QLPreviewController()
        previewController.view.frame = frame
        previewController.dataSource = self
        previewController.delegate = self
        present(previewController, animated: true)
    }

    @objc func exportButtonTapped() {
        exportButton.isEnabled = false
        activityIndicator?.startAnimating()
        exportResults()
    }
}

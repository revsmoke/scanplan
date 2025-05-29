import UIKit
import QuickLook

extension ResultsViewController: QLPreviewControllerDataSource, QLPreviewControllerDelegate {
    // MARK: - QLPreviewControllerDelegate

    func previewControllerDidDismiss(_ controller: QLPreviewController) {
        // Model cleanup happens on deinit so it can be viewed repeatedly
    }

    // MARK: - QLPreviewControllerDataSource

    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        temporaryModelURL != nil ? 1 : 0
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        guard let modelURL = temporaryModelURL else {
            DispatchQueue.main.async { [weak self] in
                controller.dismiss(animated: true) { [weak self] in
                    self?.showAlert(title: "3D Model Error", message: "The 3D model is not available or failed to generate.")
                }
            }
            return URL(fileURLWithPath: "") as QLPreviewItem
        }
        return modelURL as QLPreviewItem
    }

    // MARK: - Export Helpers

    func exportResults() {
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
            do {
                try FileManager.default.createDirectory(at: destinationFolderURL, withIntermediateDirectories: true)
            } catch {
                throw NSError(domain: "AppErrorDomain", code: 100,
                              userInfo: [NSLocalizedDescriptionKey: "Failed to create export directory: \(error.localizedDescription)"])
            }

            do {
                let jsonEncoder = JSONEncoder()
                jsonEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let jsonData = try jsonEncoder.encode(roomData)
                try jsonData.write(to: capturedRoomURL)
            } catch {
                throw NSError(domain: "AppErrorDomain", code: 101,
                              userInfo: [NSLocalizedDescriptionKey: "Failed to generate JSON data: \(error.localizedDescription)"])
            }

            do {
                try roomData.export(to: destinationURL, exportOptions: .all)
            } catch {
                throw NSError(domain: "AppErrorDomain", code: 102,
                              userInfo: [NSLocalizedDescriptionKey: "Failed to generate 3D model: \(error.localizedDescription)"])
            }

            let activityVC = UIActivityViewController(activityItems: [destinationFolderURL], applicationActivities: nil)
            activityVC.modalPresentationStyle = .popover
            activityVC.completionWithItemsHandler = { [weak self] _, _, _, _ in
                DispatchQueue.main.async {
                    self?.activityIndicator?.stopAnimating()
                    self?.exportButton.isEnabled = true
                }
            }

            present(activityVC, animated: true)
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

    func generateModel() {
        guard let roomData = finalRoomData else {
            showAlert(title: "Model Generation Failed", message: "No room data available to generate model")
            return
        }

        activityIndicator?.startAnimating()

        if let existingURL = temporaryModelURL, FileManager.default.fileExists(atPath: existingURL.path) {
            try? FileManager.default.removeItem(at: existingURL)
            temporaryModelURL = nil
        }

        let modelDirectory = FileManager.default.temporaryDirectory.appending(path: "RoomModel")
        let modelURL = modelDirectory.appending(path: "RoomPreview.usdz")

        do {
            try FileManager.default.createDirectory(at: modelDirectory, withIntermediateDirectories: true)
            if FileManager.default.fileExists(atPath: modelURL.path) {
                try FileManager.default.removeItem(at: modelURL)
            }
            try roomData.export(to: modelURL, exportOptions: .all)
            DispatchQueue.main.async { [weak self] in
                self?.temporaryModelURL = modelURL
            }
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

    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Cleanup

    func cleanupTemporaryFiles() {
        if let modelURL = temporaryModelURL, FileManager.default.fileExists(atPath: modelURL.path) {
            try? FileManager.default.removeItem(at: modelURL)
            temporaryModelURL = nil
        }

        let modelDirectory = FileManager.default.temporaryDirectory.appending(path: "RoomModel")
        if FileManager.default.fileExists(atPath: modelDirectory.path) {
            try? FileManager.default.removeItem(at: modelDirectory)
        }

        let exportDirectory = FileManager.default.temporaryDirectory.appending(path: "Export")
        if FileManager.default.fileExists(atPath: exportDirectory.path) {
            try? FileManager.default.removeItem(at: exportDirectory)
        }

        print("Temporary files cleaned up")
    }
}

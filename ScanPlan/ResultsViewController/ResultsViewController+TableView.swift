extension ResultsViewController {
    // MARK: - TableView DataSource and Delegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return measurements.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return measurements[section].items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        // Configure cell
        var configuration = cell.defaultContentConfiguration()
        
        let item = measurements[indexPath.section].items[indexPath.row]
        configuration.text = item.name
        
        // Format dimensions based on selected unit system
        let dimensionText: String
        if isMetric {
            dimensionText = String(format: "%.2f × %.2f × %.2f m", 
                                  item.width, item.height, item.length)
        } else {
            let feetPerMeter: Float = 3.28084
            dimensionText = String(format: "%.2f × %.2f × %.2f ft", 
                                  item.width * feetPerMeter, 
                                  item.height * feetPerMeter, 
                                  item.length * feetPerMeter)
        }
        configuration.secondaryText = dimensionText
        
        cell.contentConfiguration = configuration
        
        // Add accessibility
        cell.isAccessibilityElement = true
        cell.accessibilityLabel = "\(item.name): \(dimensionText)"
        cell.accessibilityHint = "Dimensions in \(isMetric ? "meters" : "feet")"
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return measurements[section].title
}

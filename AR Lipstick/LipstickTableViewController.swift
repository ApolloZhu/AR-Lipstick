/*
 AR Lipstick
 
 LipstickTableViewController.swift
 Created by Apollo Zhu on 2019/6/20.
 
 Copyright © 2019 Apollo Zhu.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import UIKit

// MARK: - Table View Data Source

let allLipstickSeries: [(brand: String, indexInBrand: Int, name: String, lipsticks: [Lipstick])] = {
    struct Wrapper: Decodable {
        let brands: [Lipstick.Brand]
    }
    let url = Bundle.main.url(forResource: "lipstick", withExtension: "json")!
    let all = try! JSONDecoder().decode(Wrapper.self, from: Data(contentsOf: url))
    return all.brands.flatMap { brand in
        brand.series.enumerated().map { (index, series) in
            return (brand: brand.name, indexInBrand: index, name: series.name, lipsticks: series.lipsticks)
        }
    }
}()

class LipstickTableViewController: UITableViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return allLipstickSeries.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allLipstickSeries[section].lipsticks.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let lipstick = allLipstickSeries[indexPath.section].lipsticks[indexPath.row]
        cell.textLabel!.text = "#\(lipstick.id)" + (lipstick.name.isEmpty ? "" : " \(lipstick.name)")
        cell.textLabel!.textColor = .white
        cell.backgroundColor = lipstick.color
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let series = allLipstickSeries[section]
        return "\(series.brand)\(series.name)"
    }
    
    // MARK: - Styling
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.layer.cornerRadius = 20
        view.clipsToBounds = true
    }
    
    // MARK: - Table View Delegate
    
    weak var delegate: LipstickChooserDelegate?
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.didChooseLipstick(allLipstickSeries[indexPath.section].lipsticks[indexPath.row])
    }
}

protocol LipstickChooserDelegate: AnyObject {
    func didChooseLipstick(_ lipstick: Lipstick)
}

//
//  LipstickCollectionViewController.swift
//  AR Lipstick
//
//  Created by Apollo Zhu on 2019/6/20.
//  Copyright © 2019 Apollo Zhu. All rights reserved.
//

import UIKit

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

class LipstickCollectionViewController: UICollectionViewController {
    
    // MARK: - UICollectionViewDataSource
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return allLipstickSeries.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allLipstickSeries[section].lipsticks.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! LipstickCollectionViewCell
        let lipstick = allLipstickSeries[indexPath.section].lipsticks[indexPath.item]
        cell.nameLabel.text = "#\(lipstick.id)" + (lipstick.name.isEmpty ? "" : " \(lipstick.name)")
        cell.colorView.backgroundColor = lipstick.color
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let cell = collectionView.dequeueReusableSupplementaryView(
            ofKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: "Header", for: indexPath)
            as! LipstickCollectionViewHeader
        let series = allLipstickSeries[indexPath.section]
        
        if series.indexInBrand == 0 {
            cell.brandLabel.text = series.brand
            cell.brandLabel.isHidden = false
        } else {
            cell.brandLabel.isHidden = true
        }
        cell.seriesLabel.text = series.name
        return cell
    }
    
    // MARK: - UICollectionViewDelegate
    
    weak var delegate: LipstickChooserDelegate?
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.didChooseLipstick(allLipstickSeries[indexPath.section].lipsticks[indexPath.item])
    }
    
}

protocol LipstickChooserDelegate: AnyObject {
    func didChooseLipstick(_ lipstick: Lipstick)
}

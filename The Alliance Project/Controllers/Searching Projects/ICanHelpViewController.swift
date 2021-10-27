//
//  ICanHelpViewController.swift
//  The Alliance Project
//
//  Created by Matthew McDonnell on 3/28/20.
//  Copyright © 2020 Matthew McDonnell. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore

class ICanHelpViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UISearchBarDelegate {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var browseCategoriesLabel: UILabel!
    
    @IBOutlet weak var searchBar: UISearchBar!
    var pickerData: [String] = [String]()
    var collectionViewPickerData: [String] = [String]()
    
    // MARK: - Override Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Search Projects"
        let attributes = [NSAttributedString.Key.font: UIFont(name: "AcherusGrotesque-Bold", size: 18)!]
        UINavigationBar.appearance().titleTextAttributes = attributes
        
        let backButton = BackBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backButton
        
        pickerData = PickerData.pickerData
        collectionViewPickerData = PickerData.collectionViewData
        
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: (collectionView.width / 2) - 6, height: (collectionView.width / 2) - 6)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        
        collectionView.register(ProjectSearchCollectionViewCell.self, forCellWithReuseIdentifier: ProjectSearchCollectionViewCell.identifier)
        collectionView.dataSource = self
        collectionView.backgroundColor = UIColor(named: "backgroundColors")
        view.addSubview(collectionView)
        self.collectionView = collectionView
        
        view.bringSubviewToFront(searchBar)
        searchBar.delegate = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        searchBar.frame = CGRect(x: 10, y: navigationController?.navigationBar.bottom ?? 20, width: view.frame.size.width - 20, height: 50)
        collectionView?.frame = CGRect(x: 15, y: browseCategoriesLabel.bottom, width: view.frame.size.width - 30, height: view.frame.size.height - browseCategoriesLabel.bottom)
    }
    
    // MARK: - Search Bar
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
        collectionView?.isHidden = false
        
        // Move to search results screen
        if searchBar.text != "" {
            let keywordSender = ProjectSearchType(keyword: searchBar.text!)
            performSegue(withIdentifier: "searchSegue", sender: keywordSender)
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchBar.showsCancelButton = true
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        // Stop doing the search stuff
        // and clear the text in the search bar
        searchBar.text = ""
        // Hide the cancel button
        searchBar.showsCancelButton = false
        // You could also change the position, frame etc of the searchBar
        searchBar.endEditing(true)
    }
    
    // MARK: - CollectionView Delegates
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionViewImages.count
    }

    
    let collectionViewImages = CategoryImages.categoryImages
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProjectSearchCollectionViewCell.identifier, for: indexPath) as? ProjectSearchCollectionViewCell else {
            return UICollectionViewCell()
        }
        cell.layer.cornerRadius = 10
        cell.configure(with: collectionViewImages[indexPath.row]!, category: collectionViewPickerData[indexPath.row])
        cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapImage(_:))))
        return cell
    }
    
    @objc func tapImage(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: collectionView)
        let indexPath = collectionView?.indexPathForItem(at: location)
        
        // Searching given the selected category
        let categorySender = ProjectSearchType(category: collectionViewPickerData[indexPath!.row])
        performSegue(withIdentifier: "searchSegue", sender: categorySender)
    }
    
    @IBAction func viewAllButton(_ sender: Any) {
        let allProjectsSender = ProjectSearchType(searchForAll: true)
        performSegue(withIdentifier: "searchSegue", sender: allProjectsSender)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let searchResultsVC = segue.destination as? SearchResultsViewController, let searchType = sender as? ProjectSearchType {
            if searchType.category != nil {
                searchResultsVC.category = searchType.category
            } else if searchType.keyword != nil {
                searchResultsVC.keyword = searchType.keyword
            } else if searchType.searchForAll != nil {
                searchResultsVC.category = "All Projects"
            }
        }
    }
    
}

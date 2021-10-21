//
//  ProjectBackgroundViewController.swift
//  The Alliance Project
//
//  Created by Matthew McDonnell on 1/27/21.
//  Copyright © 2021 Matthew McDonnell. All rights reserved.
//

import UIKit

class BackgroundImageViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UISearchBarDelegate {
    
    public var completion: (([String: String]) -> (Void))?
    var results: [PhotoResult] = []
    
    private var collectionView: UICollectionView?
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    // MARK: - Override Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Image Results"
        let attributes = [NSAttributedString.Key.font: UIFont(name: "AcherusGrotesque-Bold", size: 18)!]
        UINavigationBar.appearance().titleTextAttributes = attributes
        
        let backButton = BackBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backButton
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.itemSize = CGSize(width: view.frame.size.width / 2, height: view.frame.size.width / 2)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        
        collectionView.register(ImageCollectionViewCell.self, forCellWithReuseIdentifier: ImageCollectionViewCell.identifier)
        collectionView.dataSource = self
        collectionView.backgroundColor = UIColor(named: "backgroundColors")
        view.addSubview(collectionView)
        self.collectionView = collectionView
        
        view.bringSubviewToFront(searchBar)
        searchBar.delegate = self
        searchBar.becomeFirstResponder()
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        searchBar.frame = CGRect(x: 10, y: navigationController?.navigationBar.bottom ?? 20, width: view.frame.size.width - 20, height: 50)
        collectionView?.frame = CGRect(x: 0, y: searchBar.bottom, width: view.frame.size.width, height: view.frame.size.height)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
        
        if let text = searchBar.text {
            results = []
            collectionView?.reloadData()
            fetchPhotos(query: text)
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
    
    // MARK: - Fetch Photos
    func fetchPhotos(query: String) {
        let urlString = "https://api.unsplash.com/search/photos?page=1&per_page=50&query=\(query)&client_id=dAThptNKlrO869ksueV0rYJANsIYqqnTjCmW4Qq0T2s"
        
        let safeURLString = urlString.replacingOccurrences(of: " ", with: "-")
        guard let url = URL(string: safeURLString) else {
            return
        }
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let data = data, error == nil else {
                return
            }
            do {
                let jsonResult = try JSONDecoder().decode(APIResponse.self, from: data)
                DispatchQueue.main.async {
                    self?.results = jsonResult.results
                    self?.collectionView?.reloadData()
                }
                
            } catch {
                print(error)
            }
        }
        task.resume()
    }
    
    // MARK: - CollectionView Functions
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return results.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let imageURLString = results[indexPath.row].urls.small
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageCollectionViewCell.identifier, for: indexPath) as? ImageCollectionViewCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: imageURLString)
        cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapImage(_:))))
        return cell
    }
    
    @objc func tapImage(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: self.collectionView)
        let indexPath = self.collectionView?.indexPathForItem(at: location)
        
        if let index = indexPath {
            print("Got clicked on index: \(index)!")
        }
    }
    
}

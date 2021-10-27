//
//  ProjectBackgroundViewController.swift
//  The Alliance Project
//
//  Created by Matthew McDonnell on 1/27/21.
//  Copyright © 2021 Matthew McDonnell. All rights reserved.
//

import UIKit

class BackgroundImageViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UISearchBarDelegate {
    
    public var completion: ((PhotoResult) -> (Void))?
    var results: [PhotoResult] = []
    
    private var collectionView: UICollectionView?
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    // MARK: - Override Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Images by Unsplash"
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
        
        collectionView.isHidden = true
        
        view.bringSubviewToFront(searchBar)
        searchBar.delegate = self
        searchBar.becomeFirstResponder()
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        searchBar.frame = CGRect(x: 10, y: navigationController?.navigationBar.bottom ?? 20, width: view.frame.size.width - 20, height: 50)
        collectionView?.frame = CGRect(x: 0, y: searchBar.bottom, width: view.frame.size.width, height: view.frame.size.height)
    }
    
    @IBAction func unsplashButton(_ sender: Any) {
        let alert = UIAlertController(title: "Visit the Unsplash website", message: "This will send you outside of The Alliance Project. Continue?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Let's go", style: .default, handler: { action in
            if let path = URL(string: "https://unsplash.com?utm_source=The-Alliance-Project&utm_medium=referral") {
                    UIApplication.shared.open(path, options: [:], completionHandler: nil)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
        collectionView?.isHidden = false
        
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
        collectionView?.isHidden = true
        results = []
        collectionView?.reloadData()
    }
    
    // MARK: - Fetch Photos
    func fetchPhotos(query: String) {
        let urlString = "https://api.unsplash.com/search/photos?page=1&per_page=50&query=\(query)&content_filter=high"
        
        let safeURLString = urlString.replacingOccurrences(of: " ", with: "-")
        guard let url = URL(string: safeURLString) else {
            return
        }
        let token = "dAThptNKlrO869ksueV0rYJANsIYqqnTjCmW4Qq0T2s"
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Client-ID \(token)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
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
        let unsplashUserName = results[indexPath.row].user.name
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageCollectionViewCell.identifier, for: indexPath) as? ImageCollectionViewCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: imageURLString, name: unsplashUserName)
        cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapImage(_:))))
        return cell
    }
    
    @objc func tapImage(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: collectionView)
        let indexPath = collectionView?.indexPathForItem(at: location)
        
        let creatorName = results[indexPath!.row].user.name
        let profileURL = results[indexPath!.row].user.links.html
        let downloadLocaion = results[indexPath!.row].urls.full
        
        print("download location: \(downloadLocaion)") // Returns a URL, but I don't know  where to go from here...
        
        let actionSheet = UIAlertController(title: "Image options", message: "You can use this image in your project, or tap to view \(creatorName) on Unsplash.", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        actionSheet.addAction(UIAlertAction(title: "View \(creatorName) on Unsplash", style: .default, handler: { action in
            if let path = URL(string: "\(profileURL)?utm_source=The-Alliance-Project&utm_medium=referral") {
                    UIApplication.shared.open(path, options: [:], completionHandler: nil)
            }
        }))
        actionSheet.addAction(UIAlertAction(title: "Use this image", style: .default, handler: { [weak self] action in
            guard let strongSelf = self else {
                return
            }
            if let index = indexPath {
                print("Using image from index: \(index)!")
                strongSelf.completion!(strongSelf.results[indexPath!.row])
                strongSelf.navigationController?.popViewController(animated: true)
            }
        }))
        
        present(actionSheet, animated: true, completion: nil)
    }
    
}

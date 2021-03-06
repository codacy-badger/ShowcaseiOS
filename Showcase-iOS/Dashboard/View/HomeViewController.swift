//
//  HomeViewController.swift
//  Showcase-iOS
//
//  Created by Edward Mtshweni on 2018/05/14.
//  Copyright © 2018 DVT. All rights reserved.
//

import UIKit

class HomeViewController: UICollectionViewController {
    var presenter: HomePresentable?
    var showcaseAppsViewModels = [ShowcaseAppViewModel]()
    var filteredShowcaseAppsViewModels = [ShowcaseAppViewModel]()
    var firebaseStorage:FIRStoring?
    let searchController = UISearchController(searchResultsController: nil)
    var errorView: ErrorView?
    var loadingView: LoadingView?
    var imagesDictionary: [String: URL] = [:]
   
    override func viewDidLoad() {
        super.viewDidLoad()
        self.resolveInjectables()
        self.addRightUIBarButtonItem()
        self.navigationItem.title = "DVT Showcase"
        self.registerCollectionViewNib()
        self.addLoadingAnimationView()
        self.presenter?.fetchShowcaseApps()
    }
    
    func addRightUIBarButtonItem() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(logoutTapped))
    }
    
    func resolveInjectables() {
        let dependencyContainer = DependencyContainer.container()
        let homePresenter = dependencyContainer.resolve(HomePresentable.self) as! HomePresenter
        let firebaseStorage = dependencyContainer.resolve(FIRStoring.self)
        self.presenter = homePresenter
        homePresenter.homePresenterViewable = self
        homePresenter.firebaseStorage = firebaseStorage
        self.firebaseStorage = firebaseStorage
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.definesPresentationContext = true
        self.searchController.delegate = self
        self.searchController.searchResultsUpdater = self
        self.searchController.dimsBackgroundDuringPresentation = false
        self.navigationController?.navigationBar.items?.first?.searchController = searchController
        self.tabBarController?.tabBar.isHidden = false
        self.navigationItem.title = "DVT Showcase"
    }
    
    func registerCollectionViewNib() {
        let nib = UINib(nibName: "ShowcaseAppCollectionViewCell", bundle: nil)
        self.collectionView?.register(nib, forCellWithReuseIdentifier: "ShowcaseAppViewIdentifier")
    }
    
    func addLoadingAnimationView() {
        loadingView = LoadingView(frame: self.view.frame)
        loadingView?.isHidden = false
        self.view.addSubview(loadingView!)
    }
    
    @objc func logoutTapped() {
        self.onMainThread {
            let message = "Are you sure you want to logout?"
            let alertController = UIAlertController(title: "Logout", message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: {
                (action: UIAlertAction) in
                self.presenter?.signOutUser()
            }))
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func onMainThread(block:@escaping () -> Void) {
        DispatchQueue.main.async(execute: block)
    }
}

extension HomeViewController : UICollectionViewDelegateFlowLayout {
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredShowcaseAppsViewModels.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ShowcaseAppViewIdentifier", for: indexPath) as! ShowcaseAppCollectionViewCell
        cell.populateCell(with: filteredShowcaseAppsViewModels[indexPath.row], imageDictionary: self.imagesDictionary)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width:collectionView.frame.size.width, height:50)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width/3 - 1, height: 200)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section:Int) -> CGFloat {
        return 1.0
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let showcaseAppViewModel = self.filteredShowcaseAppsViewModels[indexPath.row]
        self.presenter?.transitionToShowcaseAppDetailView(with: showcaseAppViewModel)
    }
}

extension HomeViewController: HomePresenterViewable {
    func startLoadingAnimation() {
        loadingView?.isHidden = false
    }
    
    func stopLoadingAnimation() {
        loadingView?.isHidden = true
    }
    
    
    func showOnSuccess(with showcaseApps: [ShowcaseAppViewModel]) {
        self.showcaseAppsViewModels = showcaseApps
        presenter?.fetchAllImages(for: self.showcaseAppsViewModels, completed: { (imageDictionary) in
            self.imagesDictionary = imageDictionary
            self.filteredShowcaseAppsViewModels = self.showcaseAppsViewModels
            self.collectionView?.reloadData()
        })
    }
    
    func showOnFailure(with error: DatabaseError) {
        errorView = ErrorView(frame: self.view.bounds)
        errorView?.message.text = error.localizedDescription
        errorView?.onActionButtonTouched = {[weak self] in
            self?.presenter?.fetchShowcaseApps()
            self?.errorView?.removeFromSuperview()
        }
        self.view.addSubviewPinnedToEdges(errorView!)
    }
}

extension HomeViewController: UISearchResultsUpdating, UISearchControllerDelegate {
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let filteredShowcaseApps = self.presenter?.search(text: searchController.searchBar.text) else {
            return
        }
        self.filteredShowcaseAppsViewModels = filteredShowcaseApps
        self.collectionView?.reloadData()
    }
}

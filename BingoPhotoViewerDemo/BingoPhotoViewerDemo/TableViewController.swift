//
//  TableViewController.swift
//  BingoPhotoViewerDemo
//
//  Created by 王昱斌 on 2017/12/26.
//  Copyright © 2017年 Qtin. All rights reserved.
//

import UIKit

// This class contains some hacked together sample project code that I couldn't be arsed to make less ugly. ¯\_(ツ)_/¯
class TableViewController: UITableViewController, PhotosViewControllerDelegate, UIViewControllerPreviewingDelegate {
    
    let ReuseIdentifier = "ReuseIdentifier"
    
    var previewingContext: UIViewControllerPreviewing?
    
    var urlSession = URLSession(configuration: .default)
    var content = [Int: Data]()
    
    weak var photosViewController: PhotosViewController?
    weak var customView: UILabel?
    let att = NSAttributedString(string: "attributedTitle")
    
    
    let photos = [
        Photo(NSAttributedString(string: "attributedTitle"),
              attDescription: NSAttributedString(string: "attributedDescription"),
              attCredit: NSAttributedString(string: "attributedCredit"),
              url: URL(string: "https://goo.gl/T4oZdY"))
    ]
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.portrait, .landscapeLeft]
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if #available(iOS 9.0, *) {
            if self.traitCollection.forceTouchCapability == .available {
                if self.previewingContext == nil {
                    self.previewingContext = self.registerForPreviewing(with: self, sourceView: self.tableView)
                }
            } else if let previewingContext = self.previewingContext {
                self.unregisterForPreviewing(withContext: previewingContext)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.separatorStyle = .none
        self.tableView.contentInset = UIEdgeInsets(top: 50, left: 0, bottom: 30, right: 0)
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: ReuseIdentifier)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.tableView.scrollIndicatorInsets = UIEdgeInsets(top: UIApplication.shared.statusBarFrame.size.height,
                                                            left: 0,
                                                            bottom: 0,
                                                            right: 0)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
       return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.photos.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifier) else {
            return UITableViewCell()
        }
        
        // sample project worst practices top kek
        if cell.contentView.viewWithTag(666) == nil {
            let imageView = UIImageView()
            imageView.tag = 666
            imageView.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
            imageView.layer.cornerRadius = 20
            imageView.layer.masksToBounds = true
            imageView.contentMode = .scaleAspectFit
            cell.contentView.addSubview(imageView)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let imageView = cell.contentView.viewWithTag(666) as? UIImageView else {
            return
        }
        
        imageView.image = nil
        
        let emptyHeight: CGFloat = 200
        let emptyWidth: CGFloat = 150
        imageView.frame = CGRect(x: floor((cell.frame.size.width - emptyWidth)) / 2, y: 0, width: emptyWidth, height: emptyHeight)
        
        let maxSize = cell.frame.size.height

        self.loadContent(at: indexPath) { (uData) in
            func onMainQueue(_ block: @escaping () -> Void) {
                if Thread.isMainThread {
                    block()
                } else {
                    DispatchQueue.main.async {
                        block()
                    }
                }
            }
            
            var imageViewSize: CGSize
            if let image = UIImage(data: uData) {
                imageViewSize = (image.size.width > image.size.height) ?
                    CGSize(width: maxSize, height: (maxSize * image.size.height / image.size.width)) :
                    CGSize(width: maxSize * image.size.width / image.size.height, height: maxSize)
                
                onMainQueue {
                    imageView.image = image
                    imageView.frame.size = imageViewSize
                    imageView.center = cell.contentView.center
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 200
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        let imageView = cell?.contentView.viewWithTag(666) as? UIImageView
        
        let transitionInfo = TransitionInfo(interactiveDismissalEnabled: true, startingView: imageView) { [weak self] (photo, index) -> UIImageView? in
            guard let uSelf = self else {
                return nil
            }
            
            let indexPath = IndexPath(row: index, section: 0)
            guard let cell = uSelf.tableView.cellForRow(at: indexPath) else {
                return nil
            }
            
            // adjusting the reference view attached to our transition info to allow for contextual animation
            return cell.contentView.viewWithTag(666) as? UIImageView
        }
        
        let dataSource = PhotosDataSource(photos: self.photos, index: indexPath.row)
        let pagingConfig = PagingConfig(loadingView: LoadingView.self)//(loadingViewClass: LoadingView.self)
        let photosViewController = PhotosViewController(dataSource: dataSource, pagingConfig: pagingConfig, transitionInfo: transitionInfo)
//        photosViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        photosViewController.delegate = self
//        
//        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
//        let bottomView = UIToolbar(frame: CGRect(origin: .zero, size: CGSize(width: 320, height: 44)))
//        let customView = UILabel(frame: CGRect(origin: .zero, size: CGSize(width: 80, height: 20)))
//        customView.text = "\(photosViewController.currentPhotoIndex + 1)"
//        customView.textColor = .white
//        customView.sizeToFit()
//        bottomView.items = [
//            UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: nil),
//            flex,
//            UIBarButtonItem(customView: customView),
//            flex,
//            UIBarButtonItem(barButtonSystemItem: .trash, target: nil, action: nil),
//        ]
//        bottomView.backgroundColor = .clear
//        bottomView.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
//        photosViewController.overlayView.bottomStackContainer.insertSubview(bottomView, at: 0)
//        
//        self.customView = customView
        
//        container.addChildViewController(photosViewController)
//        container.view.addSubview(photosViewController.view)
//        photosViewController.didMove(toParentViewController: container)
        
        self.present(photosViewController, animated: true)
        self.photosViewController = photosViewController
    }
    
    // MARK: - PhotosViewControllerDelegate
    func photosViewController(_ photosViewController: PhotosViewController,
                              willUpdate overlayView: OverlayView,
                              for photo: PhotoProtocol,
                              at index: Int,
                              totalNumberOfPhotos: Int) {
        
        self.customView?.text = "\(index + 1)"
        self.customView?.sizeToFit()
    }
    
    // MARK: - Loading
    func loadContent(at indexPath: IndexPath, completion: ((_ data: Data) -> Void)?) {
        if let data = self.content[indexPath.row] {
            completion?(data)
            return
        }
        
        self.urlSession.dataTask(with: self.photos[indexPath.row].url!) { [weak self] (data, response, error) in
            guard let uData = data else {
                return
            }
            
            self?.content[indexPath.row] = uData
            completion?(uData)
        }.resume()
    }
    
    // MARK: - PhotosViewControllerDelegate
    func photosViewController(_ photosViewController: PhotosViewController,
                              didNavigateTo photo: PhotoProtocol,
                              at index: Int) {
        
        let indexPath = IndexPath(row: index, section: 0)
        
        // ideally, _your_ URL cache will be large enough to the point where this isn't necessary 
        // (or, you're using a predefined integration that has a shared cache with your codebase)
        self.loadContent(at: indexPath, completion: nil)
    }
    
    // MARK: - UIViewControllerPreviewingDelegate
    @available(iOS 9.0, *)
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = self.tableView.indexPathForRow(at: location),
            let cell = self.tableView.cellForRow(at: indexPath),
            let imageView = cell.contentView.viewWithTag(666) as? UIImageView else {
            return nil
        }
        
        previewingContext.sourceRect = self.tableView.convert(imageView.frame, from: imageView.superview)
        
        let dataSource = PhotosDataSource(photos: photos, index: indexPath.row)
        let previewingPhotosViewController = PreviewingPhotosViewController(dataSource: dataSource)
        
        return previewingPhotosViewController
    }
    
    @available(iOS 9.0, *)
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        if let previewingPhotosViewController = viewControllerToCommit as? PreviewingPhotosViewController {
            self.present(PhotosViewController(from: previewingPhotosViewController), animated: false)
        }
    }
}

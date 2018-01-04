//
//  PhotosViewController.swift
//  BingoPhotoViewerDemo
//
//  Created by 王昱斌 on 2017/12/27.
//  Copyright © 2017年 Qtin. All rights reserved.
//

import UIKit


fileprivate var PhotoVCContentOffsetContext : UInt8 = 0
fileprivate var PhotoVCLifeCycleContext: UInt8 = 0

extension Notification.Name{
    static let photoLoadingProgressUpdate = Notification.Name(rawValue: "PhotoLoadingProgressUpdateNotification")
    static let photoImageUpdate = Notification.Name(rawValue: "PhotoImageUpdateNotification")
}

@objc(PhotosViewControllerNotification)
class PhotosViewControllerNotification: NSObject {
    @objc static let ProgressUpdate = Notification.Name.photoLoadingProgressUpdate.rawValue
    @objc static let ImageUpdate = Notification.Name.photoImageUpdate.rawValue
    @objc static let ImageKey = "PhotosViewControllerImage"
    @objc static let AnimatedImageKey = "PhotosViewControllerAnimatedImage"
    @objc static let ReferenceViewKey = "PhotosViewControllerReferenceView"
    @objc static let LoadingStateKey = "PhotosViewControllerLoadingState"
    @objc static let ProgressKey = "PhotosViewControllerProgress"
    @objc static let ErrorKey = "PhotosViewControllerError"
}

@objc(PhotosViewControllerDelegate)
protocol PhotosViewControllerDelegate : NSObjectProtocol , AnyObject {
    
    @objc(photos:didNavigateToPhoto:atIndex:)
    optional func photos(
        _ vc: PhotosViewController,
        didNavigateTo photo: PhotoProtocol,
        at index: Int
        ) -> Void
    
    
    @objc(photos:willUpdateOverlayView:forPhoto:atIndex:totalNumberOfPhotos:)
    optional func photos(
        _ vc: PhotosViewController,
        willUpdate overlayView: OverlayView,
        for photo: PhotoProtocol,
        at index: Int,
        totalNumberOfPhotos: Int
        ) -> Void
    
    @objc(photos:maxScaleForPhoto:minScale:imageSize:)
    optional func photos(
        _ vc: PhotosViewController,
        maxScaleFor photo: PhotoProtocol,
        minScale: CGFloat,
        imageSize: CGSize
        ) -> CGFloat
    
    @objc(photosViewController:handleActionButtonTappedForPhoto:)
    optional func photosViewController(
        _ photosViewController: PhotosViewController,
        handleActionButtonTappedFor photo: PhotoProtocol
        ) -> Void
    
    @objc(photos:actionCompletedWithActivityType:forPhoto:)
    optional func photos(
        _ vc: PhotosViewController,
        actionCompletedWith activityType: UIActivityType,
        for photo: PhotoProtocol
        ) -> Void
    
}

@objc(PhotosViewController)
class PhotosViewController: UIViewController {

    fileprivate enum SwipeDirection {
        case none, left, right
    }
    
    @objc weak var delegate : PhotosViewControllerDelegate?
    
    @objc let overlayView = OverlayView()
    
    @objc var dataSource = PhotosDataSource(){
        didSet{
            if pageViewController == nil || networkIntegration == nil {
                return
            }
            pageViewController.dataSource = dataSource.numberOfPhotos > 1 ? self : nil
            networkIntegration.cancelAll()
            
        }
    }
    
    @objc var currentPhotoViewController: PhotoViewController? {
        get {
            return orderedViewControllers.filter({ $0.index == currentPhotoIndex }).first
        }
    }
    
    @objc fileprivate(set) var currentPhotoIndex : Int = 0{
        didSet{
            updateOverlay(for: currentPhotoIndex)
        }
    }
    
    @objc fileprivate(set) var pagingConfig = PagingConfig()
    
    @objc fileprivate(set) var transitionInfo = TransitionInfo()
    
    @objc let singleTapGestureRecognizer = UITapGestureRecognizer()
    
    @objc var closeBarButtonItem : UIBarButtonItem{
        get{
            return UIBarButtonItem(barButtonSystemItem: .stop, target: nil, action: nil)
        }
    }
    
    @objc var actionBarButtonItem: UIBarButtonItem {
        get {
            return UIBarButtonItem(barButtonSystemItem: .action, target: nil, action: nil)
        }
    }
    
    @objc fileprivate(set) var pageViewController: UIPageViewController!

    @objc fileprivate(set) var networkIntegration: NetworkIntegrationProtocol!

    
    fileprivate weak var containerViewController : UIViewController?{
        didSet{
            oldValue?.transitioningDelegate = nil
            if
                let containerViewController = containerViewController {
                transitioningDelegate = nil
                transitionController?.containerViewController = containerViewController
            }else{
                transitioningDelegate = self
                transitionController?.containerViewController = nil
            }
        }
    }
    
    
    fileprivate var isSizeTransitioning = false
    fileprivate var isForcingNonInteractiveDismissal = false
    fileprivate var isFirstAppearance = true
    
    fileprivate var orderedViewControllers = [PhotoViewController]()
    fileprivate var recycledViewControllers = [PhotoViewController]()
    
    fileprivate var transitionController: PhotosTransitionController?
    fileprivate let notificationCenter = NotificationCenter()
    
    fileprivate var b_prefersStatusBarHidden: Bool = false
    open override var prefersStatusBarHidden: Bool {
        get {
            return super.prefersStatusBarHidden || self.b_prefersStatusBarHidden
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle{
        get{
            return .lightContent
        }
    }
    
    
    @objc init() {
        super.init(nibName: nil, bundle: nil)
        commonInit()
    }
    
    @objc init(dataSource: PhotosDataSource?) {
        super.init(nibName: nil, bundle: nil)
        commonInit(dataSource: dataSource)
    }
    
    @objc init(dataSource: PhotosDataSource?,
                      pagingConfig: PagingConfig?) {
        
        super.init(nibName: nil, bundle: nil)
        commonInit(dataSource: dataSource,
                        pagingConfig: pagingConfig)
    }
    
    @objc init(pagingConfig: PagingConfig?,
                      transitionInfo: TransitionInfo?) {
        
        super.init(nibName: nil, bundle: nil)
        commonInit(pagingConfig: pagingConfig,
                        transitionInfo: transitionInfo)
    }
    
    @objc init(dataSource: PhotosDataSource?,
                      pagingConfig: PagingConfig?,
                      transitionInfo: TransitionInfo?) {
        
        super.init(nibName: nil, bundle: nil)
        commonInit(dataSource: dataSource,
                        pagingConfig: pagingConfig,
                        transitionInfo: transitionInfo)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc(initFromPreviewingPhotosViewController:)
    init(from previewingPhotosViewController: PreviewingPhotosViewController) {
        super.init(nibName: nil, bundle: nil)
        self.commonInit(dataSource: previewingPhotosViewController.dataSource,
                        networkIntegration: previewingPhotosViewController.networkIntegration)
        
        if #available(iOS 9.0, *) {
            loadViewIfNeeded()
        } else {
            let _ = self.view
        }
    }
    
    @objc(initFromPreviewingPhotosViewController:pagingConfig:)
    init(from previewingPhotosViewController: PreviewingPhotosViewController,
                pagingConfig: PagingConfig?) {
        
        super.init(nibName: nil, bundle: nil)
        commonInit(dataSource: previewingPhotosViewController.dataSource,
                        pagingConfig: pagingConfig,
                        networkIntegration: previewingPhotosViewController.networkIntegration)
        
        if #available(iOS 9.0, *) {
            loadViewIfNeeded()
        } else {
            let _ = self.view
        }
    }
    
    @objc(initFromPreviewingPhotosViewController:pagingConfig:transitionInfo:)
    init(from previewingPhotosViewController: PreviewingPhotosViewController,
                pagingConfig: PagingConfig?,
                transitionInfo: TransitionInfo?) {
        
        super.init(nibName: nil, bundle: nil)
        commonInit(dataSource: previewingPhotosViewController.dataSource,
                        pagingConfig: pagingConfig,
                        transitionInfo: transitionInfo,
                        networkIntegration: previewingPhotosViewController.networkIntegration)
        
        if #available(iOS 9.0, *) {
            loadViewIfNeeded()
        } else {
            let _ = self.view
        }
    }
    
    @nonobjc init(dataSource: PhotosDataSource? = nil,
                  pagingConfig: PagingConfig? = nil,
                  transitionInfo: TransitionInfo? = nil,
                  networkIntegration: NetworkIntegrationProtocol? = nil) {
        
        super.init(nibName: nil, bundle: nil)
        commonInit(dataSource: dataSource,
                        pagingConfig: pagingConfig,
                        transitionInfo: transitionInfo,
                        networkIntegration: networkIntegration)
    }
    
    fileprivate func commonInit(dataSource: PhotosDataSource? = nil,
                                pagingConfig: PagingConfig? = nil,
                                transitionInfo: TransitionInfo? = nil,
                                networkIntegration: NetworkIntegrationProtocol? = nil) {
        if
            let uDataSource = dataSource {
            self.dataSource = uDataSource
        }
        if
            let uPagingConfig = pagingConfig {
            self.pagingConfig = uPagingConfig
        }
        if
            let uTransitionInfo = transitionInfo {
            self.transitionInfo = uTransitionInfo
        }
        let uNetworkIntegration = BingoNetworkIntegration()
        self.networkIntegration = uNetworkIntegration
        self.networkIntegration.delegate = self
        
        pageViewController = UIPageViewController(transitionStyle: .scroll,
                                                       navigationOrientation: self.pagingConfig.orientation,
                                                       options: [UIPageViewControllerOptionInterPageSpacingKey: self.pagingConfig.spacing])
        pageViewController.delegate = self
        pageViewController.dataSource = (self.dataSource.numberOfPhotos > 1) ? self : nil
        pageViewController.scrollView.add(self)
        configurePageViewController()
        
        singleTapGestureRecognizer.numberOfTapsRequired = 1
        singleTapGestureRecognizer.addTarget(self, action: #selector(singleTapAction(_:)))
        
        overlayView.tintColor = .white
        let closeBarButtonItem = self.closeBarButtonItem
        closeBarButtonItem.target = self
        closeBarButtonItem.action = #selector(closeAction(_:))
        overlayView.leftBarButtonItem = closeBarButtonItem
        overlayView.setShowInterface(false, animated: false)
        
    }
    
    
    deinit {
        recycledViewControllers.removeLifeCycleObserver(self)
        orderedViewControllers.removeLifeCycleObserver(self)
        pageViewController.scrollView.remove(self)
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isFirstAppearance{
            overlayView.setShowInterface(true, animated: true, alongside: { [weak self] in
                if let `self` = self{
                    self.updateStatusBarAppearance(show: true)
                }
            }, completion: nil)
            isFirstAppearance = false
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .black
        
        transitionController = PhotosTransitionController(photosViewController: self, transitionInfo: transitionInfo)
        transitionController?.delegate = self
        
        if
            let containerViewController = containerViewController {
            containerViewController.transitioningDelegate = self
            transitionController?.containerViewController = containerViewController
        } else {
            transitioningDelegate = self
            transitionController?.containerViewController = nil
        }
        
        if pageViewController.view.superview == nil {
            pageViewController.view.addGestureRecognizer(singleTapGestureRecognizer)
            
            addChildViewController(pageViewController)
            view.addSubview(pageViewController.view)
            pageViewController.didMove(toParentViewController: self)
        }
        
        if overlayView.superview == nil {
            view.addSubview(overlayView)
        }
    }

    override func didMove(toParentViewController parent: UIViewController?) {
        super.didMove(toParentViewController: parent)
        if parent is UINavigationController {
            assertionFailure("Do not embed `PhotosViewController` in a navigation stack.")
            return
        }
        containerViewController = parent
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        recycledViewControllers.removeLifeCycleObserver(self)
        recycledViewControllers.removeAll()
        reduceMemoryForPhotos(at: currentPhotoIndex)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        isSizeTransitioning = true
        coordinator.animate(alongsideTransition: nil) { [weak self](context) in
            if let `self` = self{
                self.isSizeTransitioning = false
            }
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        pageViewController.view.frame = view.bounds
        overlayView.frame = view.bounds
        updateOverlayInsets()
//        overlayView.performAfterShowInterfaceCompletion { [weak self] in
//            if let `self` = self, !self.isBeingDismissed{
//                self.updateOverlayInsets()
//            }
//        }
    }
    
    

}

extension PhotosViewController{
    
    private func configure(with viewController: UIViewController, pageIndex: Int) {
        self.pageViewController.setViewControllers([viewController], direction: .forward, animated: false, completion: nil)
        currentPhotoIndex = pageIndex
        overlayView.titleView?.between?(pageIndex, high: pageIndex + 1, percent: 0)
    }
    
    fileprivate func configurePageViewController() -> Void {
        guard
            let photoViewController = makePhotoViewController(for: dataSource.index)
            else {
                configure(with: UIViewController(), pageIndex: 0)
                return
        }
        configure(with: photoViewController, pageIndex: photoViewController.index)
        loadPhotos(at: dataSource.index)
    }
    
}

// MARK: - Overlay
extension PhotosViewController{
    fileprivate func updateOverlay(for photoIndex: Int) -> Void{
        guard
            let photo = dataSource.photo(at: photoIndex)
            else {
                return
        }
        willUpdate(overlayView: overlayView, for: photo, at: photoIndex, totalNumberOfPhotos: dataSource.numberOfPhotos)
        
        if dataSource.numberOfPhotos > 1 {
            overlayView.internalTitle = NSLocalizedString("\(photoIndex + 1) of \(self.dataSource.numberOfPhotos)", comment: "")
        }else{
            overlayView.internalTitle = nil
        }
    }
    
    fileprivate func updateOverlayInsets() -> Void {
        var contentInset: UIEdgeInsets
        if #available(iOS 11.0, *) {
            contentInset = view.safeAreaInsets
        }else{
            let top : CGFloat = (UIApplication.shared.statusBarFrame.size.height > 0) ? 20 : 0
            contentInset = UIEdgeInsets(top: top, left: 0, bottom: 0, right: 0)
        }
        overlayView.contentInset = contentInset
    }
    
    fileprivate func updateStatusBarAppearance(show: Bool) -> Void {
        b_prefersStatusBarHidden = !show
        setNeedsStatusBarAppearanceUpdate()
        if show {
            UIView.performWithoutAnimation { [weak self] in
                if let `self` = self{
                    self.updateOverlayInsets()
                    overlayView.setNeedsLayout()
                    overlayView.layoutIfNeeded()
                }
            }
        }
    }
    
    @objc fileprivate func singleTapAction(_ sender: UITapGestureRecognizer) -> Void {
        let show = overlayView.alpha == 0
        overlayView.setShowInterface(show, animated: true, alongside: { [weak self] in
            if let `self` = self{
                self.updateStatusBarAppearance(show: show)
            }
        }, completion: nil)
    }
}

// MARK: - Actions
extension PhotosViewController{
    @objc func closeAction(_ sender: UIBarButtonItem) -> Void {
        if isBeingDismissed {
            return
        }
        isForcingNonInteractiveDismissal = true
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
}
// MARK: - Loading helpers
extension PhotosViewController {
    
    private func reduceMemory(for photo: PhotoProtocol) {
        weak var weakSelf = self
        guard let uSelf = weakSelf else {
            return
        }
        
        if photo.b_loadingState == .loading {
            uSelf.networkIntegration.cancelLoad(for: photo)
            photo.b_loadingState = .loadingCancelled
        }
        if photo.b_loadingState == .loaded && photo.b_isReducible {
            photo.imageData = nil
            photo.image = nil
            photo.b_loadingState = .notLoaded
        }
    }
    
    fileprivate func loadPhotos(at index: Int) -> Void {
        let numberOfPhotosToLoad = dataSource.prefetchBehavior.rawValue
        let startIndex = (((index - (numberOfPhotosToLoad / 2)) >= 0) ? (index - (numberOfPhotosToLoad / 2)) : 0)
        let indexes = startIndex...(startIndex + numberOfPhotosToLoad)
        
        for index in indexes {
            guard let photo = dataSource.photo(at: index) else {
                return
            }
            
            if photo.b_loadingState == .notLoaded || photo.b_loadingState == .loadingCancelled {
                photo.b_loadingState = .loading
                networkIntegration.loadPhoto(photo)
            }
        }
    }

    fileprivate func reduceMemoryForPhotos(at index: Int) -> Void{
        
        let numberOfPhotosToLoad = self.dataSource.prefetchBehavior.rawValue
        let lowerIndex = (index - (numberOfPhotosToLoad / 2) - 1 >= 0) ? index - (numberOfPhotosToLoad / 2) - 1: NSNotFound
        let upperIndex = (index + (numberOfPhotosToLoad / 2) + 1 < self.dataSource.numberOfPhotos) ? index + (numberOfPhotosToLoad / 2) + 1 : NSNotFound
        
        if
            lowerIndex != NSNotFound,
            let photo = self.dataSource.photo(at: lowerIndex) {
            reduceMemory(for: photo)
        }
        
        if
            upperIndex != NSNotFound,
            let photo = self.dataSource.photo(at: upperIndex) {
            reduceMemory(for: photo)
        }
    }
}
// MARK: - Reuse / Factory
extension PhotosViewController {
    fileprivate func makePhotoViewController(for index: Int) -> PhotoViewController? {
        guard let photo = dataSource.photo(at: index) else {
            return nil
        }
        
        var photoViewController: PhotoViewController
        
        if self.recycledViewControllers.count > 0 {
            photoViewController = self.recycledViewControllers.removeLast()
            photoViewController.reuse()
        } else {
            guard let loadingView = self.makeLoadingView(for: index) else {
                return nil
            }
            
            photoViewController = PhotoViewController(loadingView, notificationCenter: self.notificationCenter)
            photoViewController.addLife(self)
            photoViewController.delegate = self
            
            singleTapGestureRecognizer.require(toFail: photoViewController.zoomingImageView.doubleTapGestureRecognizer)
        }
        
        photoViewController.index = index
        photoViewController.applyPhoto(photo)
        
        let insertionIndex = orderedViewControllers.insert(photoViewController, isOrderedBefore: { $0.index < $1.index })
        if !insertionIndex.alreadyExists {
            self.orderedViewControllers.insert(photoViewController, at: insertionIndex.index)
        }
        return photoViewController
    }
    
    fileprivate func makeLoadingView(for pageIndex: Int) -> LoadingViewProtocol? {
        guard let loadingViewType = pagingConfig.loadingViewClass as? UIView.Type else {
            assertionFailure("`loadingViewType` must be a UIView.")
            return nil
        }
        return loadingViewType.init() as? LoadingViewProtocol
    }
}

// MARK: - Recycling
extension PhotosViewController {
    fileprivate func recyclePhotoViewController(_ photoVC: PhotoViewController) -> Void {
        if recycledViewControllers.contains(photoVC) {
            return
        }
        let insertionIndex = orderedViewControllers.insert(photoVC, isOrderedBefore: { $0.index < $1.index })
        if insertionIndex.alreadyExists{
            orderedViewControllers.remove(at: insertionIndex.index)
        }
        recycledViewControllers.append(photoVC)
    }
}

// MARK: - KVO
extension PhotosViewController {
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &PhotoVCLifeCycleContext {
            lifecycleContextDidUpdate(object, change: change)
        }else if context == &PhotoVCContentOffsetContext{
            contentOffsetContextDidUpdate(object, change: change)
        }else{
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    private func lifecycleContextDidUpdate(_ obj: Any?, change: [NSKeyValueChangeKey : Any]?) -> Void {
        guard
            let photoViewController = obj as? PhotoViewController
            else {
                return
        }
        if change?[.newKey] is NSNull {
            self.recyclePhotoViewController(photoViewController)
        }
    }
    
    private func contentOffsetContextDidUpdate(_ obj: Any?, change: [NSKeyValueChangeKey : Any]?) -> Void {
        guard
            let scrollView = obj as? UIScrollView,
            !isSizeTransitioning
            else {
                return
        }
        
        var percent: CGFloat
        if pagingConfig.orientation == .horizontal {
            percent = (scrollView.contentOffset.x - scrollView.frame.size.width) / scrollView.frame.size.width
        } else {
            percent = (scrollView.contentOffset.y - scrollView.frame.size.height) / scrollView.frame.size.height
        }
        
        var horizontalSwipeDirection: SwipeDirection = .none
        if percent > 0 {
            horizontalSwipeDirection = .right
        } else if percent < 0 {
            horizontalSwipeDirection = .left
        }
        
        let swipePercent = (horizontalSwipeDirection == .left) ? (1 - abs(percent)) : abs(percent)
        var lowIndex: Int = NSNotFound
        var highIndex: Int = NSNotFound
        
        let viewControllers = computeVisibleViewControllers(scrollView)
        if horizontalSwipeDirection == .left {
            guard
                let viewController = viewControllers.first
                else {
                    return
            }
            
            if viewControllers.count > 1 {
                lowIndex = viewController.index
                if lowIndex < dataSource.numberOfPhotos {
                    highIndex = lowIndex + 1
                }
            } else {
                highIndex = viewController.index
            }
        } else if horizontalSwipeDirection == .right {
            guard
                let viewController = viewControllers.last
                else {
                    return
            }
            
            if viewControllers.count > 1 {
                highIndex = viewController.index
                if highIndex > 0 {
                    lowIndex = highIndex - 1
                }
            } else {
                lowIndex = viewController.index
            }
        }
        
        guard
            lowIndex != NSNotFound && highIndex != NSNotFound
            else {
                return
        }
        
        if swipePercent < 0.5 && currentPhotoIndex != lowIndex  {
            currentPhotoIndex = lowIndex
            if
                let photo = dataSource.photo(at: lowIndex) {
                self.didNavigateTo(photo, at: lowIndex)
            }
        } else if swipePercent > 0.5 && currentPhotoIndex != highIndex {
            currentPhotoIndex = highIndex
            if
                let photo = dataSource.photo(at: highIndex) {
                didNavigateTo(photo, at: highIndex)
            }
        }
        overlayView.titleView?.between?(lowIndex, high: highIndex, percent: percent)
    }
    
    private func computeVisibleViewControllers(_ referenceView: UIScrollView) -> [PhotoViewController] {
        var visibleViewControllers = [PhotoViewController]()
        for viewController in orderedViewControllers {
            if viewController.view.frame.equalTo(.zero){
                continue
            }
            let originX = viewController.view.frame.origin.x - (pagingConfig.orientation == .horizontal ?
                (pagingConfig.spacing / 2) : 0)
            let originY = viewController.view.frame.origin.y - (pagingConfig.orientation == .vertical ?
                (pagingConfig.spacing / 2) : 0)
            let sizeWidth = viewController.view.frame.size.width + ((pagingConfig.orientation == .horizontal) ?
                pagingConfig.spacing : 0)
            let sizeHeight = viewController.view.frame.size.height + ((pagingConfig.orientation == .vertical) ?
                pagingConfig.spacing : 0)
            let conversionRect = CGRect(x: originX, y: originY, width: sizeWidth, height: sizeHeight)
            if referenceView.convert(conversionRect, from: viewController.view.superview).intersects(referenceView.bounds) {
                visibleViewControllers.append(viewController)
            }
        }
        return visibleViewControllers
    }
    
}

// MARK: - PhotosViewControllerDelegate calls
extension PhotosViewController{
    @objc(didNavigateToPhoto:atIndex:)
    func didNavigateTo(_ photo: PhotoProtocol, at index: Int) -> Void {
        guard
            let delegate = delegate,
            let function = delegate.photos(_:didNavigateTo:at:)
            else {
                return
        }
        function(self, photo, index)
    }
    
    @objc(willUpdateOverlayView:forPhoto:atIndex:totalNumberOfPhotos:)
    func willUpdate(overlayView: OverlayView, for photo: PhotoProtocol, at index: Int, totalNumberOfPhotos: Int) -> Void {
        guard
            let delegate = delegate
            else {
                return
        }
        delegate.photos?(self, willUpdate: overlayView, for: photo, at: index, totalNumberOfPhotos: totalNumberOfPhotos)
    }
    
    @objc(maximumZoomScaleForPhoto:minimumZoomScale:imageSize:)
    func maximumZoomScale(for photo: PhotoProtocol, minimumZoomScale: CGFloat, imageSize: CGSize) -> CGFloat {
        
        guard
            let delegate = delegate,
            let function = delegate.photos(_:maxScaleFor:minScale:imageSize:)
            else {
                return .leastNormalMagnitude
        }
        let scale = function(self, photo, minimumZoomScale, imageSize)
        return scale
    }
    
    @objc(handleActionButtonTappedForPhoto:)
    func handleActionButtonTapped(photo: PhotoProtocol) -> Bool {
        guard
            let delegate = delegate,
            let _ = delegate.photosViewController(_:handleActionButtonTappedFor:)
            else {
                return false
        }
        return true
    }
    
    @objc(actionCompletedWithActivityType:forPhoto:)
    func actionCompleted(activityType: UIActivityType, for photo: PhotoProtocol) {
        guard
            let delegate = delegate
            else {
                return
        }
        delegate.photos?(self, actionCompletedWith: activityType, for: photo)
    }
}

extension PhotosViewController : PhotoViewControllerDelegate{
    func photo(_ vc: PhotoViewController, retryDownload photo: PhotoProtocol) {
        guard photo.b_loadingState != .loaded && photo.b_loadingState != .loading else {
            return
        }
        photo.b_error = nil
        photo.b_loadingState = .loading
        networkIntegration.loadPhoto(photo)
    }
    
    func photo(_ vc: PhotoViewController, maxScale index: Int, minScale: CGFloat, imageSize: CGSize) -> CGFloat {
        guard
            let photo = dataSource.photo(at: index)
            else {
                return .leastNormalMagnitude
        }
        let scale = maximumZoomScale(for: photo, minimumZoomScale: minScale, imageSize: imageSize)
        return scale
    }
}

extension PhotosViewController : NetworkIntegrationDelegate{
    func network(_ integration: NetworkIntegrationProtocol, loadDidFinishWith photo: PhotoProtocol) {
        if
            let image = photo.image {
            photo.b_loadingState = .loaded
            DispatchQueue.main.async { [weak self] in
                if let `self` = self{
                    self.notificationCenter.post(
                        name: .photoImageUpdate,
                        object: photo,
                        userInfo: [
                            PhotosViewControllerNotification.ImageKey: image,
                            PhotosViewControllerNotification.LoadingStateKey: PhotoLoadingState.loaded
                        ]
                    )
                }
            }
        }
    }
    
    func network(_ integration: NetworkIntegrationProtocol, loadDidFailWith error: Error, for photo: PhotoProtocol) {
        guard
            photo.b_loadingState != .loadingCancelled
            else {
                return
        }
        photo.b_loadingState = .loadingFailed
        photo.b_error = error
        DispatchQueue.main.async { [weak self] in
            if let `self` = self{
                self.notificationCenter.post(
                    name: .photoImageUpdate,
                    object: photo,
                    userInfo: [
                        PhotosViewControllerNotification.ErrorKey : error ,
                        PhotosViewControllerNotification.LoadingStateKey : PhotoLoadingState.loadingFailed
                    ]
                )
            }
        }
        
    }
    
    func network(_ integration: NetworkIntegrationProtocol, didUpdateLoadingProgress progress: CGFloat, for photo: PhotoProtocol) {
        photo.b_process = progress
        DispatchQueue.main.async { [weak self] in
            if let `self` = self{
                self.notificationCenter.post(
                    name: .photoLoadingProgressUpdate,
                    object: photo,
                    userInfo: [PhotosViewControllerNotification.ProgressKey : progress])
            }
        }
    }
    
}

extension PhotosViewController : PhotosTransitionControllerDelegate{
    func transitionController(_ transitionController: PhotosTransitionController, didFinishAnimatingWith view: UIImageView, transitionControllerMode: PhotosTransitionControllerMode) {
        guard
            let photo = dataSource.photo(at: currentPhotoIndex)
            else {
                return
        }
        if transitionControllerMode == .presenting {
            notificationCenter.post(name: .photoImageUpdate,
                                         object: photo,
                                         userInfo: [
                                            PhotosViewControllerNotification.ReferenceViewKey: view
                ]
            )
        }
    }
}

extension PhotosViewController : UIPageViewControllerDelegate{
    
}

extension PhotosViewController : UIPageViewControllerDataSource{
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        guard
            let viewController = pendingViewControllers.first as? PhotoViewController
            else {
                return
        }
        loadPhotos(at: viewController.index)
    }
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard
            let viewController = pageViewController.viewControllers?.first as? PhotoViewController
            else {
                return
        }
        reduceMemoryForPhotos(at: viewController.index)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard
            let vc = viewController as? PhotoViewController
            else {
                assertionFailure("Paging VC must be a subclass of `PhotoViewController`.")
                return nil
        }
        let _viewController = pageVC(pageViewController, viewControllerAt: vc.index - 1)
        return _viewController
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard
            let vc = viewController as? PhotoViewController
            else {
                assertionFailure("Paging VC must be a subclass of `PhotoViewController`.")
                return nil
        }
        let _viewController = pageVC(pageViewController, viewControllerAt: vc.index + 1)
        return _viewController
    }
    
    private func pageVC(_ vc: UIPageViewController, viewControllerAt index: Int) -> UIViewController? {
        guard
            index >= 0 && self.dataSource.numberOfPhotos > index
            else {
                return nil
        }
        return makePhotoViewController(for: index)
    }
}

extension PhotosViewController : UIViewControllerTransitioningDelegate{
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let photo = self.dataSource.photo(at: self.currentPhotoIndex) else {
            return nil
        }
        
        self.transitionInfo.resolveEndingViewClosure?(photo, self.currentPhotoIndex)
        guard let transitionController = self.transitionController, transitionController.supportsModalPresentationStyle(self.modalPresentationStyle) &&
            (transitionController.supportsContextualDismissal ||
                transitionController.supportsInteractiveDismissal) else {
                    return nil
        }
        
        transitionController.mode = .dismissing
        return transitionController
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let transitionController = self.transitionController, transitionController.supportsModalPresentationStyle(self.modalPresentationStyle) &&
            transitionController.supportsContextualPresentation else {
                return nil
        }
        
        transitionController.mode = .presenting
        return transitionController
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        guard let transitionController = self.transitionController, transitionController.supportsInteractiveDismissal &&
            !self.isForcingNonInteractiveDismissal else {
                return nil
        }
        
        return transitionController
    }
}

fileprivate extension UIScrollView{
    
    func add(_ observer: NSObject) -> Void {
        addObserver(observer, forKeyPath: #keyPath(contentOffset), options: .new, context: &PhotoVCContentOffsetContext)
    }
    
    func remove(_ observer: NSObject) -> Void {
        removeObserver(observer, forKeyPath: #keyPath(contentOffset), context: &PhotoVCContentOffsetContext)
    }
    
}

fileprivate extension UIPageViewController{
    
    var scrollView : UIScrollView{
        get{
            guard let scrollView = self.view.subviews.filter({$0 is UIScrollView}).first as? UIScrollView else {
                fatalError("Unable to locate the underlying `UIScrollView`")
            }
            return scrollView
        }
    }
    
}

fileprivate extension UIViewController{
    
    func addLife(_ observer: NSObject) -> Void {
        addObserver(observer, forKeyPath: #keyPath(parent), options: .new, context: &PhotoVCLifeCycleContext)
    }
    
    func removeLife(_ observer: NSObject) -> Void {
        removeObserver(observer, forKeyPath: #keyPath(parent), context: &PhotoVCLifeCycleContext)
    }
    
}

fileprivate extension Array where Element: UIViewController{
    
    func removeLifeCycleObserver(_ observer: NSObject) -> Void {
        self.forEach({($0 as UIViewController).removeLife(observer)})
    }
    
}



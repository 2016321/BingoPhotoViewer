//
//  PhotoViewController.swift
//  BingoPhotoViewerDemo
//
//  Created by 王昱斌 on 2017/12/27.
//  Copyright © 2017年 Qtin. All rights reserved.
//

import UIKit
@objc(PhotoViewControllerDelegate)
protocol PhotoViewControllerDelegate : NSObjectProtocol , AnyObject {
    
    @objc(photo:retryDownload:)
    func photo(_ vc: PhotoViewController, retryDownload photo: PhotoProtocol) -> Void
    
    @objc(photo:maxScale:minScale:imageSize:)
    func photo(_ vc: PhotoViewController, maxScale index: Int, minScale: CGFloat, imageSize: CGSize) -> CGFloat
    
}

@objc(PhotoViewController)
class PhotoViewController: UIViewController{
    
    @objc weak var delegate : PhotoViewControllerDelegate?
    
    @objc public var index : Int = 0
    
    @objc fileprivate(set) var loadingView : LoadingViewProtocol?
    
    @objc var zoomingImageView : ZoomingImageView{
        get{
            return view as! ZoomingImageView
        }
    }
    
    fileprivate var photo : PhotoProtocol?
    fileprivate weak var notificationCenter: NotificationCenter?
    
    
    init(_ loadingView: LoadingViewProtocol, notificationCenter: NotificationCenter) {
        self.loadingView = loadingView
        self.notificationCenter = notificationCenter
        super.init(nibName: nil, bundle: nil)
        
        notificationCenter.addObserver(self,
                                       selector: #selector(photoLoadingProgressDidUpdate(_:)),
                                       name: .photoLoadingProgressUpdate,
                                       object: nil)
        
        notificationCenter.addObserver(self,
                                       selector: #selector(photoImageDidUpdate(_:)),
                                       name: .photoImageUpdate,
                                       object: nil)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.notificationCenter?.removeObserver(self)
    }
    
    override func loadView() {
        self.view = ZoomingImageView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        zoomingImageView.zoomScaleDelegate = self
        if
            let loadingView = loadingView as? UIView {
            view.addSubview(loadingView)
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        var adjustedSize : CGSize = self.view.bounds.size
        if #available(iOS 11.0, *) {
            adjustedSize.width -= (self.view.safeAreaInsets.left + self.view.safeAreaInsets.right)
            adjustedSize.height -= (self.view.safeAreaInsets.top + self.view.safeAreaInsets.bottom)
        }
        let loadingViewSize : CGSize = self.loadingView?.sizeThatFits(adjustedSize) ?? .zero//fits(adjustedSize) ?? .zero
        
        guard let loadingView = self.loadingView as? UIView else {
            return
        }
        let originX = floor((self.view.bounds.size.width - loadingViewSize.width) / 2)
        let originY = floor((self.view.bounds.size.height - loadingViewSize.height) / 2)
        let origin = CGPoint(x: originX, y: originY)
        loadingView.frame = CGRect(origin: origin, size: adjustedSize)
    }

}
extension PhotoViewController{
    
    private func resetImageView() -> Void {
        weak var weakSelf = self
        weakSelf?.zoomingImageView.image = nil
    }
    
    @objc func applyPhoto(_ photo: PhotoProtocol) -> Void {
        self.photo = photo
        loadingView?.removeError()
        switch photo.b_loadingState {
        case .loading, .notLoaded, .loadingCancelled:
            resetImageView()
            loadingView?.start(photo.b_process)
        case .loadingFailed:
            resetImageView()
        case .loaded:
            guard photo.image != nil else{
                assertionFailure("Must provide valid `UIImage` in \(#function)")
                return
            }
            loadingView?.stop()
            if let image = photo.image{
                zoomingImageView.image = image
            }
        }
        view.setNeedsLayout()
    }
}


extension PhotoViewController{
    
    @objc fileprivate func photoLoadingProgressDidUpdate(_ noti: Notification) -> Void {
        guard
            let photo = noti.object as? PhotoProtocol
            else {
                assertionFailure("Photos must conform to the Photo protocol.")
                return
        }
        guard
            photo === self.photo,
            let userInfo = noti.userInfo,
            let process = userInfo[PhotosViewControllerNotification.ProgressKey] as? CGFloat
            else {
                return
        }
        loadingView?.update?(process)
    }
    
    @objc fileprivate func photoImageDidUpdate(_ noti: Notification) -> Void {
        
        guard
            let photo = noti.object as? PhotoProtocol
            else {
                assertionFailure("Photos must conform to the Photo protocol.")
                return
        }
        guard
            photo === self.photo,
            let userInfo = noti.userInfo
            else {
                return
        }
        
        if userInfo[PhotosViewControllerNotification.ImageKey] != nil{
            applyPhoto(photo)
        }
        if
            let error = userInfo[PhotosViewControllerNotification.ErrorKey] as? Error,
            let loadingView = loadingView{
            loadingView.show(error, retryHandler: {[weak self] in
                guard
                    let `self` = self,
                    let photo = self.photo
                    else{
                        return
                }
                self.delegate?.photo(self, retryDownload: photo)
                self.loadingView?.removeError()
                self.loadingView?.start(photo.b_process)
                self.view.setNeedsLayout()
            })
            self.view.setNeedsLayout()
        }
    }
}

extension PhotoViewController : PageableViewControllerProtocol{
    func reuse() {
        zoomingImageView.image = nil
    }
}

extension PhotoViewController : ZoomingImageViewDelegate{
    func zoomingImageView(_ zoomingImageView: ZoomingImageView, maximumZoomScaleFor imageSize: CGSize) -> CGFloat {
        guard
            let delegate = delegate
            else {
                return .leastNormalMagnitude
        }
        let value = delegate.photo(self, maxScale: index, minScale: zoomingImageView.minimumZoomScale, imageSize: imageSize)
        return value
    }
}



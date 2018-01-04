//
//  PreviewingPhotosViewController.swift
//  BingoPhotoViewerDemo
//
//  Created by 王昱斌 on 2017/12/29.
//  Copyright © 2017年 Qtin. All rights reserved.
//

import UIKit

@objc(PreviewingPhotosViewController)
class PreviewingPhotosViewController: UIViewController {
    
    var imageView : UIImageView{
        get{
            return self.view as! UIImageView
        }
    }
    
    @objc public fileprivate(set) var networkIntegration: NetworkIntegrationProtocol!
    
    @objc var dataSource : PhotosDataSource = PhotosDataSource(){
        didSet{
            if self.networkIntegration == nil {
                return
            }
            networkIntegration.cancelAll()
            configure(dataSource.index)
        }
    }
    
    override func loadView() {
        view = imageView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.contentMode = .scaleAspectFit
        configure(dataSource.index)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        var newSize : CGSize
        if imageView.image == nil {
            newSize = CGSize(width: imageView.frame.size.width, height: imageView.frame.size.height * 9.0 / 16.0)
        }else{
            newSize = imageView.intrinsicContentSize
        }
        preferredContentSize = newSize
    }
   
    @objc init(dataSource: PhotosDataSource) {
        super.init(nibName: nil, bundle: nil)
        commonInit(_dataSource: dataSource)
    }
    
    @objc init(_dataSource: PhotosDataSource, networkIntegration: NetworkIntegrationProtocol) {
        super.init(nibName: nil, bundle: nil)
        commonInit(_dataSource: _dataSource)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension PreviewingPhotosViewController{
    
    fileprivate func commonInit(_dataSource: PhotosDataSource, _networkIntegration: NetworkIntegrationProtocol? = nil) -> Void {
        dataSource = _dataSource
        let uNetworkIntegration = BingoNetworkIntegration()
        networkIntegration = uNetworkIntegration
        networkIntegration.delegate = self
    }
    
    fileprivate func configure(_ index: Int) -> Void {
        guard let photo = dataSource.photo(at: index) else {
            return
        }
        networkIntegration.loadPhoto(photo)
    }
    
}

extension PreviewingPhotosViewController: NetworkIntegrationDelegate {
    
    func network(_ integration: NetworkIntegrationProtocol, loadDidFinishWith photo: PhotoProtocol) {
        if let image = photo.image {
            photo.b_loadingState = .loaded
            DispatchQueue.main.async { [weak self] in
                if let `self` = self{
                    self.imageView.image = image
                    self.view.setNeedsLayout()
                }
            }
        }
    }
    
    func network(_ integration: NetworkIntegrationProtocol, loadDidFailWith error: Error, for photo: PhotoProtocol) {
        guard photo.b_loadingState != .loadingCancelled else {
            return
        }
        photo.b_loadingState = .loadingFailed
        photo.b_error = error
    }
    
    func network(_ integration: NetworkIntegrationProtocol, didUpdateLoadingProgress process: CGFloat, for photo: PhotoProtocol) -> Void {
        photo.b_process = process
    }
    
}

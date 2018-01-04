//
//  ZoomingImageView.swift
//  BingoPhotoViewerDemo
//
//  Created by 王昱斌 on 2018/1/2.
//  Copyright © 2018年 Qtin. All rights reserved.
//

import UIKit


fileprivate let ZoomScaleEpsilon : CGFloat = 0.01

@objc(ZoomingImageViewDelegate)
protocol ZoomingImageViewDelegate : NSObjectProtocol , AnyObject {
    @objc(zoomingImageView:maximumZoomScaleForImageSize:)
    func zoomingImageView(_ zoomingImageView: ZoomingImageView, maximumZoomScaleFor imageSize: CGSize) -> CGFloat
}

@objc(ZoomingImageView)
class ZoomingImageView: UIScrollView {

    weak var zoomScaleDelegate: ZoomingImageViewDelegate?

    var image: UIImage?{
        set{
            updateImageView(newValue)
        }
        get{
            return imageView.image
        }
    }
    
    override var frame: CGRect{
        didSet{
            updateZoomScale()
        }
    }
    
    fileprivate var needsUpdateImageView = false
    fileprivate(set) var doubleTapGestureRecognizer = UITapGestureRecognizer()
    fileprivate(set) var imageView = UIImageView()
    
    
    init() {
        super.init(frame: .zero)
        
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        doubleTapGestureRecognizer.addTarget(self, action: #selector(doubleTapAction(_:)))
        doubleTapGestureRecognizer.isEnabled = false
        addGestureRecognizer(self.doubleTapGestureRecognizer)
        
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFit
        addSubview(self.imageView)
        
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        isScrollEnabled = false
        bouncesZoom = true
        decelerationRate = UIScrollViewDecelerationRateFast;
        delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}

extension ZoomingImageView{
    
    override func didAddSubview(_ subview: UIView) {
        super.didAddSubview(subview)
        if subview === imageView && needsUpdateImageView{
            updateImageView(image)
        }
    }
    
    override func willRemoveSubview(_ subview: UIView) {
        super.willRemoveSubview(subview)
        if subview === imageView {
            needsUpdateImageView = true
        }
    }
    
}

extension ZoomingImageView{
    
    fileprivate func updateImageView(_ image: UIImage?) -> Void {
        self.imageView.transform = .identity
        var imageSize: CGSize = .zero
        if let image = image {
            if imageView.image != image{
                imageView.image = image
            }
            imageSize = image.size
        }else{
            imageView.image = nil
        }
        imageView.frame = CGRect(origin: .zero, size: imageSize)
        contentSize = imageSize
        updateZoomScale()
        doubleTapGestureRecognizer.isEnabled = (image != nil)
        needsUpdateImageView = false
        
    }
    
    fileprivate func updateZoomScale() -> Void {
        
        let imageSize = imageView.image?.size ?? CGSize(width: 1, height: 1)
        let scaleWidth = self.bounds.size.width / imageSize.width
        let scaleHeight = self.bounds.size.height / imageSize.height
        self.minimumZoomScale = min(scaleWidth, scaleHeight)
        
        let delegatedMaxZoomScale = self.zoomScaleDelegate?.zoomingImageView(self, maximumZoomScaleFor: imageSize)
        if let maximumZoomScale = delegatedMaxZoomScale, (maximumZoomScale - self.minimumZoomScale) >= 0 {
            self.maximumZoomScale = maximumZoomScale
        } else {
            self.maximumZoomScale = self.minimumZoomScale * 3.5
        }
        
        if abs(self.zoomScale - self.minimumZoomScale) <= .ulpOfOne {
            self.zoomScale = self.minimumZoomScale + 0.1
        }
        
        self.zoomScale = self.minimumZoomScale
        self.isScrollEnabled = false
    }
    
    @objc fileprivate func doubleTapAction(_ sender: UITapGestureRecognizer) -> Void {
        
        let point = sender.location(in: self.imageView)
        
        var _zoomScale = maximumZoomScale
        
        if zoomScale >= maximumZoomScale || abs(zoomScale - maximumZoomScale) <= ZoomScaleEpsilon {
            _zoomScale = minimumZoomScale
        }
        
        if abs(zoomScale - _zoomScale) <= .ulpOfOne {
            return
        }
        
        let width = bounds.size.width / _zoomScale
        let height = bounds.size.height / _zoomScale
        let originX = point.x - (width / 2)
        let originY = point.y - (height / 2)
        let zoomRect = CGRect(x: originX, y: originY, width: width, height: height)
        
        zoom(to: zoomRect, animated: true)
        
    }
    
}

extension ZoomingImageView : UIScrollViewDelegate{
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
    
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        scrollView.isScrollEnabled = true
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let offSetX = (scrollView.bounds.size.width > scrollView.contentSize.width) ? (scrollView.bounds.size.width - scrollView.contentSize.width) / 2 : 0
        let offSetY = (scrollView.bounds.size.height > scrollView.contentSize.height) ?
            (scrollView.bounds.size.height - scrollView.contentSize.height) / 2 : 0
        self.imageView.center = CGPoint(x: offSetX + (scrollView.contentSize.width / 2), y: offSetY + (scrollView.contentSize.height / 2))
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        guard abs(scale - minimumZoomScale) <= ZoomScaleEpsilon else {
            return
        }
        scrollView.isScrollEnabled = false
    }
    
}

















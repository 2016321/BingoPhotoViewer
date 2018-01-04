//
//  PagingConfig.swift
//  BingoPhotoViewerDemo
//
//  Created by 王昱斌 on 2017/12/27.
//  Copyright © 2017年 Qtin. All rights reserved.
//

import UIKit

fileprivate let defaultSpacing : CGFloat = 20

@objc(PagingConfig)
class PagingConfig: NSObject {
    
    @objc fileprivate(set) var orientation : UIPageViewControllerNavigationOrientation
    
    @objc fileprivate(set) var spacing : CGFloat
    
    @objc fileprivate(set) var loadingViewClass: LoadingViewProtocol.Type = LoadingView.self
    
    @objc public init(
        orientation: UIPageViewControllerNavigationOrientation,
        spacing: CGFloat,
        loadingView theClass: LoadingViewProtocol.Type? = nil
        ) {
        
        self.orientation = orientation
        self.spacing = spacing
        
        super.init()
        
        if let theClass = theClass {
            guard theClass is UIView.Type else{
                assertionFailure("`loadingViewClass` must be a UIView.")
                return
            }
        }
    }
    
    @objc public override convenience init() {
        self.init(orientation: .horizontal, spacing: defaultSpacing, loadingView: nil)
    }
    
    @objc public convenience init(orientation: UIPageViewControllerNavigationOrientation) {
        self.init(orientation: orientation, spacing: defaultSpacing, loadingView: nil)
    }
    
    @objc public convenience init(spacing: CGFloat) {
        self.init(orientation: .horizontal, spacing: spacing, loadingView: nil)
    }
    
    @objc public convenience init(loadingView theClass: LoadingViewProtocol.Type?) {
        self.init(orientation: .horizontal, spacing: defaultSpacing, loadingView: theClass)
    }
    
}

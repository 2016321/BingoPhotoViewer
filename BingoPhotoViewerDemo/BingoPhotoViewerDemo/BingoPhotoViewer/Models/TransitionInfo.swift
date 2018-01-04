//
//  TransitionInfo.swift
//  BingoPhotoViewerDemo
//
//  Created by 王昱斌 on 2017/12/29.
//  Copyright © 2017年 Qtin. All rights reserved.
//

import UIKit

class TransitionInfo: NSObject {
    
    var resolveEndingViewClosure : ((_ photo: PhotoProtocol, _ index: Int) -> Void)?
    
    @objc var duration : TimeInterval = 0.3
    
    @objc fileprivate(set) var interactiveDismissalEnabled: Bool = true
    
    @objc fileprivate(set) weak var startingView : UIImageView?
    
    @objc fileprivate(set) weak var endingView : UIImageView?
    
    
    @objc init(interactiveDismissalEnabled: Bool, startingView: UIImageView?, endingView: ((_ photo: PhotoProtocol, _ index: Int) -> UIImageView?)?) {
        super.init()
        
        self.interactiveDismissalEnabled = interactiveDismissalEnabled
        
        if let startingView = startingView {
            
            guard startingView.bounds != .zero else{
                assertionFailure("'startingView' has invalid geometry: \(startingView)")
                return
            }
            self.startingView = startingView
        }
        
        if let endingView = endingView {
            self.resolveEndingViewClosure = { [weak self] (photo, index) in
                
                guard let `self` = self else{
                    return
                }
                
                if let endingView = endingView(photo, index) {
                    guard endingView.bounds != .zero else {
                        self.endingView = nil
                        assertionFailure("'endingView' has invalid geometry: \(endingView)")
                        return
                    }
                    
                    self.endingView = endingView
                }else{
                    self.endingView = nil
                }
            }
        }
    }
    
    @objc convenience override init() {
        self.init(interactiveDismissalEnabled: true, startingView: nil, endingView: nil)
    }
    
    @objc convenience init(
        startingView: UIImageView?,
        endingView: ((_ photo: PhotoProtocol, _ index: Int) -> UIImageView?)?
        ) {
        self.init(interactiveDismissalEnabled: true, startingView: startingView, endingView: endingView)
    }
    
}

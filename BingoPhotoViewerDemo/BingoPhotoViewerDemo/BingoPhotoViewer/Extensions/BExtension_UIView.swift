//
//  6_11_UIView.swift
//  BingoPhotoViewerDemo
//
//  Created by 王昱斌 on 2017/12/29.
//  Copyright © 2017年 Qtin. All rights reserved.
//

import Foundation
import UIKit

extension UIView{
    
    class func animate(cornerRadius duration: TimeInterval, to value: CGFloat, views: [UIView], completion: ((Bool) -> Void)? = nil) -> Void {
        
        assert(views.count > 0, "Must call `animateCornerRadii:duration:value:views:completion:` with at least 1 view.")
        
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            if let completion = completion{
                completion(true)
            }
        }
        
        for view in views {
            
            view.layer.masksToBounds = true
            
            let animation = CABasicAnimation(keyPath: #keyPath(CALayer.cornerRadius))
            animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
            animation.fromValue = view.layer.cornerRadius
            animation.toValue = value
            animation.duration = duration
            
            view.layer.add(animation, forKey: "CornerRadiusAnim")
            view.layer.cornerRadius = value
        }
        
        CATransaction.commit()
        
    }
}

//
//  6_11_UIImageView.swift
//  BingoPhotoViewerDemo
//
//  Created by 王昱斌 on 2017/12/29.
//  Copyright © 2017年 Qtin. All rights reserved.
//

import Foundation
import UIKit

extension UIImageView : NSCopying{
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let imageView = type(of: self).init()
        imageView.image = self.image
        imageView.transform = self.transform
        imageView.bounds = self.bounds
        imageView.layer.cornerRadius = self.layer.cornerRadius
        imageView.layer.masksToBounds = self.layer.masksToBounds
        imageView.contentMode = self.contentMode
        return imageView
    }
    
}

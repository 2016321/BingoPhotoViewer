//
//  PageableViewControllerProtocol.swift
//  BingoPhotoViewerDemo
//
//  Created by 王昱斌 on 2017/12/26.
//  Copyright © 2017年 Qtin. All rights reserved.
//

import Foundation
import UIKit

@objc(PageableViewControllerProtocol)
protocol PageableViewControllerProtocol: AnyObject, NSObjectProtocol {
    
    var index: Int { get set }
    
    @objc optional func reuse() -> Void
    
    @objc optional func recycle() -> Void
    
}

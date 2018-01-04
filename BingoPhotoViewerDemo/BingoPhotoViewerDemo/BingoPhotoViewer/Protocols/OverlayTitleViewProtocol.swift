//
//  OverlayTitleViewProtocol.swift
//  BingoPhotoViewerDemo
//
//  Created by 王昱斌 on 2017/12/26.
//  Copyright © 2017年 Qtin. All rights reserved.
//

import Foundation
import UIKit

@objc(OverlayTitleViewProtocol)
protocol OverlayTitleViewProtocol : NSObjectProtocol {
    
    @objc func sizeToFit() -> Void
    
    @objc optional func between(_ low: Int, high: Int, percent: CGFloat) -> Void
    
}

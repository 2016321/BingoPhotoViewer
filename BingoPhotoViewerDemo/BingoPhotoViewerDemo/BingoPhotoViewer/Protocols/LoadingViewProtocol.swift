//
//  LoadingViewProtocol.swift
//  BingoPhotoViewerDemo
//
//  Created by 王昱斌 on 2017/12/26.
//  Copyright © 2017年 Qtin. All rights reserved.
//

import Foundation
import UIKit

@objc(LoadingViewProtocol)
protocol LoadingViewProtocol : NSObjectProtocol {
    
    @objc func start(_ initialProcess: CGFloat) -> Void
    
    @objc func stop() -> Void
    
    @objc optional func update(_ process: CGFloat) -> Void
    
    @objc func show(_ error: Error, retryHandler: @escaping (() -> ())) -> Void
    
    @objc func removeError() -> Void
//    @objc func fits(_ size: CGSize) -> CGSize
    @objc func sizeThatFits(_ size: CGSize) -> CGSize
}

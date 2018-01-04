//
//  CaptionViewProtocol.swift
//  BingoPhotoViewerDemo
//
//  Created by 王昱斌 on 2017/12/26.
//  Copyright © 2017年 Qtin. All rights reserved.
//
//
import Foundation
import UIKit

@objc(CaptionViewProtocol)
protocol CaptionViewProtocol : NSObjectProtocol{
    
    @objc var animateChanges : Bool { get set }
    
    @objc func apply(
        _ title: NSAttributedString?,
        description: NSAttributedString?,
        credit: NSAttributedString?
        ) -> Void
    
    @objc func fit(_ size: CGSize) -> CGSize
    
}

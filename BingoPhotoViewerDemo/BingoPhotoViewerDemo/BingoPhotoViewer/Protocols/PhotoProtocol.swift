//
//  PhotoProtocol.swift
//  BingoPhotoViewerDemo
//
//  Created by 王昱斌 on 2017/12/26.
//  Copyright © 2017年 Qtin. All rights reserved.
//

import Foundation
import UIKit

@objc(PhotoProtocol)
protocol PhotoProtocol : NSObjectProtocol , AnyObject {
    
    @objc optional var attTitle : NSAttributedString? { get }
     
    @objc optional var attDescription : NSAttributedString? { get }
    
    @objc optional var attCredit : NSAttributedString? { get }
    
    @objc var imageData : Data? { set get }
    
    @objc var image : UIImage? { set get}
    
    @objc var url : URL? { get }
    
}

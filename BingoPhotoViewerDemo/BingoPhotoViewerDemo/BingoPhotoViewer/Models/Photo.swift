//
//  Photo.swift
//  BingoPhotoViewerDemo
//
//  Created by 王昱斌 on 2017/12/26.
//  Copyright © 2017年 Qtin. All rights reserved.
//

import UIKit

@objc(Photo)
class Photo: NSObject, PhotoProtocol {
    
    @objc public init(_ attTitle: NSAttributedString? = nil,
                      attDescription: NSAttributedString? = nil,
                      attCredit: NSAttributedString? = nil,
                      imageData: Data? = nil,
                      image: UIImage? = nil,
                      url: URL? = nil) {
        
        self.attTitle = attTitle
        self.attDescription = attDescription
        self.attCredit = attCredit
        self.imageData = imageData
        self.image = image
        self.url = url
        
        super.init()
    }
    
    @objc public var attTitle : NSAttributedString?
    
    @objc public var attDescription : NSAttributedString?
    
    @objc public var attCredit : NSAttributedString?
    
    @objc public var imageData : Data?
    
    @objc public var image : UIImage?
    
    @objc public var url : URL?
    
}
















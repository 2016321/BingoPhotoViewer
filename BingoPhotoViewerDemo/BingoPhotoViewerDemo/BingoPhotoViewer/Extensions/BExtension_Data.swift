//
//  BExtension_Data.swift
//  BingoPhotoViewerDemo
//
//  Created by 王昱斌 on 2018/1/2.
//  Copyright © 2018年 Qtin. All rights reserved.
//

import Foundation
import MobileCoreServices
import ImageIO

extension Data{
    
    func containsGIF() -> Bool {
        
        let  sourceData = self as CFData
        let option : [String : Any] = [kCGImageSourceShouldCache as String : false]
        guard
            let source = CGImageSourceCreateWithData(sourceData, option as CFDictionary?),
            let sourceContainerType = CGImageSourceGetType(source)
        else {
            return false
        }
        return UTTypeConformsTo(sourceContainerType, kUTTypeGIF)
    }
    
}

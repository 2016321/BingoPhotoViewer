//
//  BExtension_PhotoProtocol.swift
//  BingoPhotoViewerDemo
//
//  Created by 王昱斌 on 2017/12/29.
//  Copyright © 2017年 Qtin. All rights reserved.
//

import Foundation
import UIKit

enum PhotoLoadingState : Int {
    case notLoaded = 0
    case loading = 1
    case loaded = 2
    case loadingCancelled = 3
    case loadingFailed = 4
}

fileprivate struct AssociationKeys {
    static var error: UInt8 = 0
    static var process: UInt8 = 0
    static var loadingState: UInt8 = 0
    static var animationImage: UInt8 = 0
}


extension PhotoProtocol{
    
    var b_error: Error?{
        set{
            objc_setAssociatedObject(self, &AssociationKeys.error, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
        get{
            return objc_getAssociatedObject(self, &AssociationKeys.error) as? Error
        }
    }
    
    var b_process : CGFloat{
        set{
            objc_setAssociatedObject(self, &AssociationKeys.process, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
        get{
            return objc_getAssociatedObject(self, &AssociationKeys.process) as? CGFloat ?? 0
        }
    }
    
    var b_loadingState : PhotoLoadingState{
        set{
            objc_setAssociatedObject(self, &AssociationKeys.loadingState, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
        get{
            return objc_getAssociatedObject(self, &AssociationKeys.loadingState) as? PhotoLoadingState ?? .notLoaded
        }
    }
    
//    var b_animationImage : UIImage?{
//        set{
//            objc_setAssociatedObject(self, &AssociationKeys.animationImage, newValue, .OBJC_ASSOCIATION_RETAIN)
//        }
//        get{
//            guard
//                let image = objc_getAssociatedObject(self, &AssociationKeys.animationImage) as? UIImage else {
//                return nil
//            }
//            return image
//        }
//    }
    
    var b_isReducible : Bool{
        get{
            return self.url != nil
        }
    }
    
    
}

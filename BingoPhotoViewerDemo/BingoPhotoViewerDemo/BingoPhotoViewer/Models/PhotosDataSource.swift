//
//  PhotosDataSource.swift
//  BingoPhotoViewerDemo
//
//  Created by 王昱斌 on 2017/12/26.
//  Copyright © 2017年 Qtin. All rights reserved.
//

import UIKit

@objc(PhotosPrefetchBehavior)
public enum PhotosPrefetchBehavior: Int {
    case conservative = 0
    case regular      = 2
    case aggressive   = 4
}

@objc(PhotosDataSource)
class PhotosDataSource: NSObject {
    
    @objc public var numberOfPhotos: Int {
        return self.photos.count
    }
    
    fileprivate var photos: [PhotoProtocol]
    
    @objc fileprivate(set) var index: Int = 0
    
    @objc fileprivate(set) var prefetchBehavior: PhotosPrefetchBehavior
    
    @objc public init(photos: [PhotoProtocol], index: Int, prefetchBehavior: PhotosPrefetchBehavior) {
        self.photos = photos
        self.prefetchBehavior = prefetchBehavior
        
        if photos.count > 0 {
            assert(photos.count > index, "Invalid initial photo index provided.")
            self.index = index
        }
        
        super.init()
    }
    
    @objc public convenience override init() {
        self.init(photos: [], index: 0, prefetchBehavior: .regular)
    }
    
    @objc public convenience init(photos: [PhotoProtocol]) {
        self.init(photos: photos, index: 0, prefetchBehavior: .regular)
    }
    
    @objc public convenience init(photos: [PhotoProtocol], index: Int) {
        self.init(photos: photos, index: index, prefetchBehavior: .regular)
    }
    
    @objc public func photo(at index: Int) -> PhotoProtocol? {
        if index < self.photos.count {
            return self.photos[index]
        }
        return nil
    }
    
}









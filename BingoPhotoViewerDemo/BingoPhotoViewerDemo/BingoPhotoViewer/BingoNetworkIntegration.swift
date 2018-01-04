//
//  BingoNetworkIntegration.swift
//  BingoPhotoViewerDemo
//
//  Created by 王昱斌 on 2018/1/3.
//  Copyright © 2018年 Qtin. All rights reserved.
//

import UIKit
import Kingfisher

class BingoNetworkIntegration: NSObject {
    
    weak var delegate: NetworkIntegrationDelegate?
    fileprivate var retrieveImageTasks = NSMapTable<PhotoProtocol, RetrieveImageTask>(keyOptions: .strongMemory, valueOptions: .strongMemory)
}

extension BingoNetworkIntegration : NetworkIntegrationProtocol{
    
    
    func loadPhoto(_ photo: PhotoProtocol){
        if photo.imageData != nil || photo.image != nil {
            delegate?.network(self, loadDidFinishWith: photo)
        }
        
        guard let url = photo.url else {
            return
        }
        
        let progress: DownloadProgressBlock = { [weak self] (receivedSize, totalSize) in
            guard let uSelf = self else {
                return
            }
            
            uSelf.delegate?.network?(uSelf, didUpdateLoadingProgress: CGFloat(receivedSize) / CGFloat(totalSize), for: photo)
        }
        
        let completion: CompletionHandler = { [weak self] (image, error, cacheType, imageURL) in
            guard let uSelf = self else {
                return
            }
            self?.retrieveImageTasks.removeObject(forKey: photo)
            if let error = error {
                uSelf.delegate?.network(uSelf, loadDidFailWith: error, for: photo)
            } else {
                if let image = image {
                    photo.image = image
                }
                
                uSelf.delegate?.network(uSelf, loadDidFinishWith: photo)
            }
        }
        
        let task = KingfisherManager.shared.retrieveImage(with: url, options: nil, progressBlock: progress, completionHandler: completion)
        self.retrieveImageTasks.setObject(task, forKey: photo)
    }
    
    func cancelLoad(for photo: PhotoProtocol){
        guard
            let downloadTask = retrieveImageTasks.object(forKey: photo)
            else {
                return
        }
        downloadTask.cancel()
    }
    
    func cancelAll(){
        guard
            let enumerator = retrieveImageTasks.objectEnumerator()
            else{
                return
        }
        while let downloadTask = enumerator.nextObject() as? RetrieveImageTask {
            downloadTask.cancel()
        }
        retrieveImageTasks.removeAllObjects()
    }
}




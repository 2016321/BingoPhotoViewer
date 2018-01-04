//
//  NetworkIntegrationProtocol.swift
//  BingoPhotoViewerDemo
//
//  Created by 王昱斌 on 2017/12/26.
//  Copyright © 2017年 Qtin. All rights reserved.
//

import Foundation
import UIKit

@objc(NetworkIntegrationProtocol)
protocol NetworkIntegrationProtocol : NSObjectProtocol , AnyObject {
    
    @objc weak var delegate: NetworkIntegrationDelegate? { get set }
    
    @objc func loadPhoto(_ photo: PhotoProtocol)
    
    @objc func cancelLoad(for photo: PhotoProtocol)
    
    @objc func cancelAll()
    
}

@objc(NetworkIntegrationDelegate)
protocol NetworkIntegrationDelegate: AnyObject, NSObjectProtocol {
    
    @objc func network(
        _ integration: NetworkIntegrationProtocol,
        loadDidFinishWith photo: PhotoProtocol
        ) -> Void
    
    @objc func network(
        _ integration: NetworkIntegrationProtocol,
        loadDidFailWith error: Error,
        for photo: PhotoProtocol
        ) -> Void
    
    @objc optional func network(
        _ integration: NetworkIntegrationProtocol,
        didUpdateLoadingProgress progress: CGFloat,
        for photo: PhotoProtocol
        ) -> Void
    
    
}

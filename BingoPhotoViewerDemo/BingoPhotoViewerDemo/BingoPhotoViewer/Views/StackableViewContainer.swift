//
//  StackableViewContainer.swift
//  BingoPhotoViewerDemo
//
//  Created by 王昱斌 on 2018/1/2.
//  Copyright © 2018年 Qtin. All rights reserved.
//

import UIKit

@objc(StackableViewContainerDelegate)
protocol StackableViewContainerDelegate : NSObjectProtocol , AnyObject {
    @objc optional func stackableViewContainer(_ vc: StackableViewContainer, didAddSubview: UIView) -> Void
    @objc optional func stackableViewContainer(_ vc: StackableViewContainer, willRemoveSubview: UIView) -> Void
}


@objc(StackableViewContainer)
class StackableViewContainer: UIView {
    
    @objc(StackableViewContainerAnchorPoint)
    enum StackableViewContainerAnchorPoint : Int {
        case top, bottom
    }
    
    weak var delegate: StackableViewContainerDelegate?
    
    var contentInset : UIEdgeInsets = .zero
    
    @objc fileprivate(set) var anchorPoint: StackableViewContainerAnchorPoint

    
    init(views: [UIView], anchoredAt point: StackableViewContainerAnchorPoint) {
        anchorPoint = point
        super.init(frame: .zero)
        for view in views {
            addSubview(view)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        computeSize(for: frame.size, applySizingLayout: true)
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return computeSize(for: size, applySizingLayout: false)
    }
    
    override func didAddSubview(_ subview: UIView) {
        super.didAddSubview(subview)
        guard
            let delegate = delegate ,
            let function = delegate.stackableViewContainer(_:didAddSubview:)
            else {
                return
        }
        function(self, subview)
    }
    
    override func willRemoveSubview(_ subview: UIView) {
        super.willRemoveSubview(subview)
        guard
            let delegate = delegate ,
            let function = delegate.stackableViewContainer(_:willRemoveSubview:)
            else {
            return
        }
        function(self, subview)
    }
    

}

extension StackableViewContainer{
    
    @discardableResult fileprivate func computeSize(for constrainedSize: CGSize, applySizingLayout: Bool) -> CGSize {
        
        var yOffset: CGFloat = 0
        let xOffset: CGFloat = self.contentInset.left
        var constrainedInsetSize = constrainedSize
        constrainedInsetSize.width -= (self.contentInset.left + self.contentInset.right)
        
        let subviews = (self.anchorPoint == .top) ? self.subviews : self.subviews.reversed()
        for subview in subviews {
            let size = subview.sizeThatFits(constrainedInsetSize)
            var frame: CGRect
            
            if yOffset == 0 && size.height > 0 {
                yOffset = self.contentInset.top
            }
            
            if subview is UIToolbar || subview is UINavigationBar {
                frame = CGRect(x: xOffset, y: yOffset, width: constrainedInsetSize.width, height: size.height)
            } else {
                frame = CGRect(origin: CGPoint(x: xOffset, y: yOffset), size: size)
            }
            
            yOffset += frame.size.height
            
            if applySizingLayout {
                subview.frame = frame
                subview.setNeedsLayout()
                subview.layoutIfNeeded()
            }
        }
        
        if (yOffset - self.contentInset.top) > 0 {
            yOffset += self.contentInset.bottom
        }
        
        return CGSize(width: constrainedSize.width, height: yOffset)
    }
    
}

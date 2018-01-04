//
//  OverlayView.swift
//  BingoPhotoViewerDemo
//
//  Created by 王昱斌 on 2017/12/29.
//  Copyright © 2017年 Qtin. All rights reserved.
//

import UIKit

class OverlayView: UIView {

    @objc var title : String?{
        didSet{
            updateTitleBarButtonItem()
        }
    }
    
    @objc var internalTitle : String?{
        didSet{
            updateTitleBarButtonItem()
        }
    }
    
    @objc var titleTextAttributes : [NSAttributedStringKey : Any]?{
        didSet{
            updateTitleBarButtonItem()
        }
    }
    
    @objc var titleViewBarButtonItem : UIBarButtonItem?
    
    @objc var titleView : OverlayTitleViewProtocol?{
        didSet{
            assert(self.titleView == nil ? true : self.titleView is UIView, "`titleView` must be a UIView.")
            if self.window == nil {
                return
            }
            updateToolbarBarButtonItems()
        }
    }
    
    @objc var contentInset: UIEdgeInsets = .zero
    
    @objc var topStackContainer : StackableViewContainer!
    
    @objc var bottomStackContainer : StackableViewContainer!
    
    @objc var leftBarButtonItem : UIBarButtonItem?{
        set{
            if let newValue = newValue {
                leftBarButtonItems = [newValue]
            }else{
                leftBarButtonItems = nil
            }
        }
        get{
            return leftBarButtonItems?.first
        }
    }
    
    @objc var leftBarButtonItems : [UIBarButtonItem]?{
        didSet{
            if self.window == nil {
                return
            }
            updateToolbarBarButtonItems()
        }
    }
    
    @objc var rightBarButtonItem : UIBarButtonItem?{
        set{
            if let newValue = newValue {
                rightBarButtonItems = [newValue]
            }else{
                rightBarButtonItems = nil
            }
        }
        get{
            return rightBarButtonItems?.first
        }
    }
    
    @objc var rightBarButtonItems : [UIBarButtonItem]?{
        didSet{
            if window == nil {
                return
            }
            updateToolbarBarButtonItems()
        }
    }
    
    @objc let toolbar = UIToolbar(frame: CGRect(origin: .zero, size: CGSize(width: 320, height: 44)))
    
    @objc let titleBarButtonItem = UIBarButtonItem(customView: UILabel())
    
    fileprivate var isFirstLayout: Bool = true
    
    init() {
        super.init(frame: .zero)
        
        toolbar.backgroundColor = .clear
        toolbar.setBackgroundImage(UIImage(), forToolbarPosition: UIBarPosition.any, barMetrics: UIBarMetrics.default)
        
        topStackContainer = StackableViewContainer(views: [self.toolbar], anchoredAt: .top)
        topStackContainer.backgroundColor = Constants.overlayForegroundColor
        topStackContainer.delegate = self
        addSubview(topStackContainer)
        
        bottomStackContainer = StackableViewContainer(views: [], anchoredAt: .bottom)
        bottomStackContainer.backgroundColor = Constants.overlayForegroundColor
        bottomStackContainer.delegate = self
        addSubview(bottomStackContainer)
        
        NotificationCenter.default.addObserver(forName: .UIContentSizeCategoryDidChange, object: nil, queue: .main) { [weak self] (noti) in
            DispatchQueue.main.async {
                if let `self` = self{
                    self.setNeedsLayout()
                }
            }
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.topStackContainer.contentInset = UIEdgeInsets(top: contentInset.top,
                                                           left: contentInset.left,
                                                           bottom: 0,
                                                           right: contentInset.right)
        self.topStackContainer.frame = CGRect(origin: .zero, size: topStackContainer.sizeThatFits(frame.size))
        
        self.bottomStackContainer.contentInset = UIEdgeInsets(top: 0,
                                                              left: contentInset.left,
                                                              bottom: contentInset.bottom,
                                                              right: contentInset.right)
        let bottomStackSize = bottomStackContainer.sizeThatFits(frame.size)
        bottomStackContainer.frame = CGRect(origin: CGPoint(x: 0, y: frame.size.height - bottomStackSize.height),
                                                 size: bottomStackSize)
        
        isFirstLayout = false
        
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            updateToolbarBarButtonItems()
        }
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let view = super.hitTest(point, with: event) as? UIControl {
            return view
        }
        return nil
    }
    
}

// MARK: - Show / hide interface
extension OverlayView{
    func setShowInterface(_ show: Bool, animated: Bool, alongside closure: (() -> Void)? = nil, completion: ((Bool) -> Void)? = nil) -> Void {
        let alpha: CGFloat = show ? 1 : 0
        guard self.alpha != alpha else {
            return
        }
        
        if alpha == 1 {
            self.isHidden = false
        }
        
        let animations = { [weak self] in
            self?.alpha = alpha
            closure?()
        }
        
        let internalCompletion: (_ finished: Bool) -> Void = { [weak self] (finished) in
            guard alpha == 0 else {
                completion?(finished)
                return
            }
            
            self?.isHidden = true
            completion?(finished)
        }
        
        if animated {
            UIView.animate(withDuration: Constants.frameAnimDuration,
                           animations: animations,
                           completion: internalCompletion)
        } else {
            animations()
            internalCompletion(true)
        }
    }
}

// MARK: - UIToolBar
extension OverlayView{
    
    private func defaultAttributes() -> [NSAttributedStringKey : Any] {
        let pointSize : CGFloat = 17.0
        var font : UIFont
        if #available(iOS 8.2, *) {
            font = UIFont.systemFont(ofSize: pointSize, weight: UIFont.Weight.semibold)
        }else{
            font = UIFont(name: "HelveticaNeue-Medium", size: pointSize)!
        }
        return [
            NSAttributedStringKey.font : font,
            NSAttributedStringKey.foregroundColor : UIColor.white
        ]
    }
    
    func updateTitleBarButtonItem() {
        func defaultAttributes() -> [NSAttributedStringKey: Any] {
            let pointSize: CGFloat = 17.0
            var font: UIFont
            if #available(iOS 8.2, *) {
                font = UIFont.systemFont(ofSize: pointSize, weight: UIFont.Weight.semibold)
            } else {
                font = UIFont(name: "HelveticaNeue-Medium", size: pointSize)!
            }
            
            return [
                NSAttributedStringKey.font: font,
                NSAttributedStringKey.foregroundColor: UIColor.white
            ]
        }
        
        var attributedText: NSAttributedString?
        if let title = self.title {
            attributedText = NSAttributedString(string: title,
                                                attributes: self.titleTextAttributes ?? defaultAttributes())
        } else if let internalTitle = self.internalTitle {
            attributedText = NSAttributedString(string: internalTitle,
                                                attributes: self.titleTextAttributes ?? defaultAttributes())
        }
        
        if let attributedText = attributedText {
            guard let titleBarButtonItemLabel = self.titleBarButtonItem.customView as? UILabel else {
                return
            }
            
            if titleBarButtonItemLabel.attributedText != attributedText {
                titleBarButtonItemLabel.attributedText = attributedText
                titleBarButtonItemLabel.sizeToFit()
            }
        }
    }
    
    func updateToolbarBarButtonItems() {
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let fixedSpace = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        fixedSpace.width = Constants.overlayBarButtonItemSpacing
        
        var barButtonItems = [UIBarButtonItem]()
        if let leftBarButtonItems = self.leftBarButtonItems {
            let last = leftBarButtonItems.last
            for barButtonItem in leftBarButtonItems {
                barButtonItems.append(barButtonItem)
                
                if barButtonItem != last {
                    barButtonItems.append(fixedSpace)
                }
            }
        }
        
        barButtonItems.append(flexibleSpace)
        
        var centerBarButtonItem: UIBarButtonItem?
        if let titleView = self.titleView as? UIView {
            if let titleViewBarButtonItem = self.titleViewBarButtonItem, titleViewBarButtonItem.customView === titleView {
                centerBarButtonItem = titleViewBarButtonItem
            } else {
                self.titleViewBarButtonItem = UIBarButtonItem(customView: titleView)
                centerBarButtonItem = self.titleViewBarButtonItem
            }
        } else {
            centerBarButtonItem = self.titleBarButtonItem
        }
        
        if let centerBarButtonItem = centerBarButtonItem {
            barButtonItems.append(centerBarButtonItem)
            barButtonItems.append(flexibleSpace)
        }
        
        if let rightBarButtonItems = self.rightBarButtonItems?.reversed() {
            let last = rightBarButtonItems.last
            for barButtonItem in rightBarButtonItems {
                barButtonItems.append(barButtonItem)
                
                if barButtonItem != last {
                    barButtonItems.append(fixedSpace)
                }
            }
        }
        
        self.toolbar.items = barButtonItems
    }
}


extension OverlayView : StackableViewContainerDelegate{
    
    func stackableViewContainer(_ vc: StackableViewContainer, didAddSubview: UIView) {
        setNeedsLayout()
    }
    
    func stackableViewContainer(_ vc: StackableViewContainer, willRemoveSubview: UIView) {
        DispatchQueue.main.async {[weak self] in
            if let `self` = self{
                self.setNeedsLayout()
            }
        }
    }
    
}

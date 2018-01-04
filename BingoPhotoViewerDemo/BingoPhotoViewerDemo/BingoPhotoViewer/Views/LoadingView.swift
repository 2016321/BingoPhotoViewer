//
//  LoadingView.swift
//  BingoPhotoViewerDemo
//
//  Created by 王昱斌 on 2017/12/28.
//  Copyright © 2017年 Qtin. All rights reserved.
//

import UIKit

@objc(LoadingView)
class LoadingView: UIView{
    
    @objc fileprivate(set) lazy var indicatorView : UIView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.white)
    
    @objc fileprivate(set) var errorImageView : UIImageView?
    
    @objc fileprivate(set) var errorLabel : UILabel?

    @objc fileprivate(set) var retryHandler: (() -> Void)?
    
    @objc var errorImage : UIImage?{
        get{
            // FIXME : -
            return UIImage(named: "error")
        }
    }
    
    @objc var errorText : String{
        return "加载错误"
    }
    
    @objc var retryText: String {
        return "重试"
    }
    
    @objc var errorAttributes : [NSAttributedStringKey : Any]{
        get{
            var fontDescriptor: UIFontDescriptor
            var font: UIFont
            
            if #available(iOS 10.0, *) {
                fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body, compatibleWith: self.traitCollection)
            } else {
                fontDescriptor = UIFont.preferredFont(forTextStyle: .body).fontDescriptor
            }
            
            if #available(iOS 8.2, *) {
                font = UIFont.systemFont(ofSize: fontDescriptor.pointSize, weight: UIFont.Weight.light)
            } else {
                font = UIFont(name: "HelveticaNeue-Light", size: fontDescriptor.pointSize)!
            }
            return [
                NSAttributedStringKey.font: font,
                NSAttributedStringKey.foregroundColor: UIColor.white
            ]
        }
    }
    
    @objc var retryAttributes: [NSAttributedStringKey: Any] {
        get {
            var fontDescriptor: UIFontDescriptor
            if #available(iOS 10.0, *) {
                fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body,
                                                                          compatibleWith: self.traitCollection)
            } else {
                fontDescriptor = UIFont.preferredFont(forTextStyle: .body).fontDescriptor
            }
            
            var font: UIFont
            if #available(iOS 8.2, *) {
                font = UIFont.systemFont(ofSize: fontDescriptor.pointSize, weight: UIFont.Weight.light)
            } else {
                font = UIFont(name: "HelveticaNeue-Light", size: fontDescriptor.pointSize)!
            }
            
            return [
                NSAttributedStringKey.font: font,
                NSAttributedStringKey.foregroundColor: UIColor.white
            ]
        }
    }
    
    @objc fileprivate(set) var retryButton : UIButton?
    
    @objc init() {
        super.init(frame: .zero)
        NotificationCenter.default.addObserver(forName: .UIContentSizeCategoryDidChange, object: nil, queue: .main) { [weak self](noti) in
            if let `self` = self{
                self.setNeedsLayout()
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return computeSize(for: size, applySizingLayout: false)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        computeSize(for: frame.size, applySizingLayout: true)
    }
    
}

extension LoadingView{
    
    private func makeAttributedStringWithAttributes(_ attributes: [NSAttributedStringKey: Any], for attributedString: NSAttributedString?) -> NSAttributedString? {
        guard let newAttributedString = attributedString?.mutableCopy() as? NSMutableAttributedString else {
            return attributedString
        }
        newAttributedString.setAttributes(nil, range: NSMakeRange(0, newAttributedString.length))
        newAttributedString.addAttributes(attributes, range: NSMakeRange(0, newAttributedString.length))
        return newAttributedString.copy() as? NSAttributedString
    }
    
    @discardableResult
    fileprivate func computeSize(for size: CGSize, applySizingLayout: Bool) -> CGSize {
        
        let ImageViewVerticalPadding : CGFloat = 20
        let VerticalPadding : CGFloat = 10
        var totalHeight : CGFloat = 0
        
        var indicatorViewSize: CGSize = .zero
        var errorImageViewSize: CGSize = .zero
        var errorLabelSize: CGSize = .zero
        var retryButtonSize: CGSize = .zero
        
        if
            let errorLabel = self.errorLabel,
            let retryButton = self.retryButton
        {
            if
                let errorImageView = self.errorImageView
            {
                errorImageViewSize = errorImageView.sizeThatFits(size)
                totalHeight += errorImageViewSize.height
                totalHeight += ImageViewVerticalPadding
            }
            
            errorLabel.attributedText = makeAttributedStringWithAttributes(self.errorAttributes, for: errorLabel.attributedText)
            errorLabelSize = errorLabel.sizeThatFits(size)
            totalHeight += errorLabelSize.height
            
            let retryButtonAtt = makeAttributedStringWithAttributes(self.retryAttributes, for: retryButton.attributedTitle(for: .normal))
            retryButton.setAttributedTitle(retryButtonAtt, for: .normal)
            
            let RetryButtonLabelPadding: CGFloat = 10.0
            retryButtonSize = retryButton.titleLabel?.sizeThatFits(size) ?? .zero
            retryButtonSize.width += RetryButtonLabelPadding
            retryButtonSize.height += RetryButtonLabelPadding
            totalHeight += retryButtonSize.height
            totalHeight += VerticalPadding
        }else{
            indicatorViewSize = self.indicatorView.sizeThatFits(size)
            totalHeight += indicatorViewSize.height
        }
        
        if applySizingLayout {
            
            var yOffset: CGFloat = (size.height - totalHeight) / 2.0
            
            if
                let errorLabel = self.errorLabel,
                let retryButton = self.retryButton
            {
                if
                    let errorImageView = self.errorImageView
                {
                    let errorImageViewOrigin = CGPoint(x: floor((size.width - errorImageViewSize.width) / 2), y: floor(yOffset))
                    errorImageView.frame = CGRect(origin: errorImageViewOrigin, size: errorImageViewSize)
                    yOffset += errorImageViewSize.height
                    yOffset += ImageViewVerticalPadding
                }
                
                let errorLabelOrigin = CGPoint(x: floor((size.width - errorLabelSize.width) / 2), y: floor(yOffset))
                errorLabel.frame = CGRect(origin: errorLabelOrigin, size: errorLabelSize)
                
                yOffset += errorLabelSize.height
                yOffset += VerticalPadding
                
                let retryButtonOrigin = CGPoint(x: floor((size.width - retryButtonSize.width) / 2), y: floor(yOffset))
                retryButton.frame = CGRect(origin: retryButtonOrigin, size: retryButtonSize)
            } else {
                let indicatorViewOrigin = CGPoint(x: floor((size.width - indicatorViewSize.width) / 2), y: floor(yOffset))
                self.indicatorView.frame = CGRect(origin: indicatorViewOrigin, size: indicatorViewSize)
            }
        }
        
        return CGSize(width: size.width, height: totalHeight)
        
    }
    
}

extension LoadingView {
    
    @objc func retryButtonAction(_ sender: Any?) -> Void {
        guard
            let retryHandler = retryHandler else {
                return
        }
        retryHandler()
        self.retryHandler = nil
    }
    
}


extension LoadingView : LoadingViewProtocol{
    
    func start(_ initialProgress: CGFloat) -> Void {
        if self.indicatorView.superview == nil {
            self.addSubview(self.indicatorView)
            self.setNeedsLayout()
        }
        
        if
            let indicatorView = self.indicatorView as? UIActivityIndicatorView,
            !indicatorView.isAnimating
        {
            indicatorView.startAnimating()
        }
    }
    
    func stop() -> Void {
        if
            let indicatorView = self.indicatorView as? UIActivityIndicatorView,
            indicatorView.isAnimating
        {
            indicatorView.stopAnimating()
        }
    }
    
    func update(_ process: CGFloat) -> Void{
        
    }
    func show(_ error: Error, retryHandler: @escaping (() -> ())) {
        
        self.stop()
        self.retryHandler = retryHandler
        
        if
            let errorImage = self.errorImage
        {
            errorImageView = UIImageView(image: errorImage)
            errorImageView?.tintColor = .white
            self.addSubview(self.errorImageView!)
        }else{
            self.errorImageView?.removeFromSuperview()
            self.errorImageView = nil
        }
        
        self.errorLabel = UILabel()
        self.errorLabel?.attributedText = NSAttributedString(string: self.errorText, attributes: self.errorAttributes)
        self.errorLabel?.textAlignment = .center
        self.errorLabel?.numberOfLines = 3
        self.errorLabel?.textColor = .white
        self.addSubview(self.errorLabel!)
        
        self.retryButton = UIButton()
        self.retryButton?.layer.cornerRadius = 2
        self.retryButton?.layer.borderColor = UIColor.white.cgColor
        self.retryButton?.setTitle(" 重试 ", for: .normal)
        self.retryButton?.setTitleColor(.white, for: .normal)
        self.retryButton?.sizeToFit()
        self.retryButton?.addTarget(self, action: #selector(retryButtonAction(_:)), for: .touchUpInside)
        self.addSubview(self.retryButton!)
        
        self.setNeedsLayout()
    }
    
    func removeError() -> Void {
        
        if let errorImageView = self.errorImageView {
            errorImageView.removeFromSuperview()
            self.errorImageView = nil
        }
        
        if let errorLabel = self.errorLabel {
            errorLabel.removeFromSuperview()
            self.errorLabel = nil
        }
        
        if let retryButton = self.retryButton {
            retryButton.removeFromSuperview()
            self.retryButton = nil
        }
        
        self.retryHandler = nil
        
    }
    
    func fits(_ size: CGSize) -> CGSize{
        return computeSize(for: size, applySizingLayout: false)
    }
}

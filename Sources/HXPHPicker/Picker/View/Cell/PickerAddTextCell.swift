//
//  PickerAddTextCell.swift
//  ustories
//
//  Created by imac3 on 12/06/2023.
//

import UIKit

class PickerAddTextCell: UICollectionViewCell {
    
    
    
//    lazy var imageView: UIImageView = {
//        let imageView = UIImageView()
//        return imageView
//    }()
    lazy var titleLbl: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    var config: PhotoListConfiguration.AddTextCell? {
        didSet {
            configProperty()
        }
    }
    var allowPreview = true
    override init(frame: CGRect) {
        super.init(frame: frame)
       // contentView.addSubview(captureView)
//        contentView.addSubview(imageView)
        contentView.addSubview(titleLbl)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func configProperty() {
        //        imageView.image = UIImage.image(for: PhotoManager.isDark ?   config?.cameraDarkImageName :  config?.cameraImageName)
        
        backgroundColor = .red//PhotoManager.isDark ? config?.backgroundDarkColor : config?.backgroundColor
        //        imageView.size = imageView.image?.size ?? .zero
        //        self.titleLbl.text = "plain text"
        
        titleLbl.text = config?.title?.localized
//        let isDark = PhotoManager.isDark
//        backgroundColor = isDark ? config?.backgroundDarkColor : config?.backgroundColor
        titleLbl.textColor = config?.titleColor
        titleLbl.font = config?.titleFont
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        titleLbl.center = CGPoint(x: width * 0.5, y: height * 0.5)
        titleLbl.x = 0
        titleLbl.y = (height) * 0.5
        titleLbl.width = width
        titleLbl.height = titleLbl.textHeight
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                configProperty()
            }
        }
    }
    deinit {
        
    }
}

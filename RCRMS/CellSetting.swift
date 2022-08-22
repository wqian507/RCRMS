//
//  CellSetting.swift
//  RCRMS
//
//  Created by Wei Qian on 11/29/17.
//  Copyright © 2017 Wei Qian. All rights reserved.
//

import UIKit

class BaseCell: UICollectionViewCell {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func setupView(){
        
    }
}

class CellSetting:BaseCell{
    
    override var isHighlighted: Bool{
        didSet{
            if(isHighlighted){
                backgroundColor=UIColor.darkGray
                lbName.textColor=UIColor.white
                imgIcon.tintColor=UIColor.white
            }
            else{
                backgroundColor=UIColor.white
                lbName.textColor=UIColor.black
                imgIcon.tintColor=UIColor.darkGray
            }
        }
    }
    
    var setting:Setting?{
        didSet{
            lbName.text=setting?.name
            if let imgName=setting?.imgName{
                imgIcon.image=UIImage(named:imgName)?.withRenderingMode(.alwaysTemplate)
                imgIcon.tintColor=UIColor.darkGray
            }
        }
    }
    
    let lbName: UILabel = {
        let label=UILabel()
        label.text="Report"
        label.font=UIFont.systemFont(ofSize: 13)
        return label
    }()
    
    let imgIcon:UIImageView={
        let imgView=UIImageView()
        imgView.image=UIImage(named:"comment")
        imgView.contentMode = .scaleAspectFill
        return imgView
    }()
    
    override func setupView() {
        super.setupView()
        addSubview(lbName)
        addSubview(imgIcon)
        addConstraintsWithFormat(format: "H:|-12-[v0(30)]-12-[v1]|", views: imgIcon,lbName)
        addConstraintsWithFormat(format: "V:|[v0]|", views: lbName)
        addConstraintsWithFormat(format: "V:|-10-[v0(30)]|", views: imgIcon)
        
        addConstraints([NSLayoutConstraint(item: imgIcon, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0)])
    }
    
    func addConstraintsWithFormat(format: String, views: UIView...) {
        
        var viewsDict = [String: UIView]()
        
        for (index, view) in views.enumerated() {
            
            view.translatesAutoresizingMaskIntoConstraints = false
            viewsDict["v\(index)"] = view
        }
        
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: format, options: NSLayoutFormatOptions(), metrics: nil, views: viewsDict))
    }
}

//
//  SettingLuncher.swift
//  RCRMS
//
//  Created by Wei Qian on 11/29/17.
//  Copyright © 2017 Wei Qian. All rights reserved.
//

import UIKit

class SettingLancher:NSObject{
    let mv=MapViewController()
    let blackView=UIView()
    
    func showSettings(){
        if let window = UIApplication.shared.keyWindow{
            blackView.backgroundColor=UIColor(white:0,alpha:0.5)
            blackView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleDismiss)))
            window.addSubview(blackView)
            blackView.frame=window.frame
            blackView.alpha=0
            UIView.animate(withDuration: 0.5, animations: {
                self.blackView.alpha=1
            })
        }
    }
    
    @objc func handleDismiss(){
        UIView.animate(withDuration: 0.5) {
            self.blackView.alpha=0
            self.mv.mapView.clear()
        }
    }
}

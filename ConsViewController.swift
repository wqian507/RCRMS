//
//  ConsViewController.swift
//  RCRMS
//
//  Created by Wei Qian on 11/13/17.
//  Copyright © 2017 Wei Qian. All rights reserved.
//

import UIKit

class ConsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let newBackButton = UIBarButtonItem(title: "Back", style: UIBarButtonItemStyle.plain, target: self, action: #selector(ReportViewController.back(sender:)))
        self.navigationItem.title="Construction"
        self.navigationItem.leftBarButtonItem = newBackButton
        // Do any additional setup after loading the view.
    }

    @objc func back(sender: UIBarButtonItem) {
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let resultViewController = storyBoard.instantiateViewController(withIdentifier: "SWRevealViewController") as! SWRevealViewController
        self.present(resultViewController, animated:true, completion:nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

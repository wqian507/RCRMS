//
//  MenuViewController.swift
//  RCRMS
//
//  Created by Wei Qian on 11/11/17.
//  Copyright © 2017 Wei Qian. All rights reserved.
//

import UIKit

class MenuViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {

    var menuName:Array=[String]()
    var menuImg:Array=[UIImage]()

    override func viewDidLoad() {
        super.viewDidLoad()
        menuName=["Report","Mark History","Construction","Feedback"]
        menuImg=[UIImage(named:"report")!,UIImage(named:"history")!,UIImage(named:"construction")!,UIImage(named:"feedback")!]
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuName.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell=tableView.dequeueReusableCell(withIdentifier: "MenuTableViewCell") as! MenuTableViewCell
        cell.imgIcon.image=menuImg[indexPath.row]
        cell.lbName.text!=menuName[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let revealViewController:SWRevealViewController=self.revealViewController()
        let cell:MenuTableViewCell=tableView.cellForRow(at: indexPath) as! MenuTableViewCell
        
        if cell.lbName.text! == "Report"
        {
            let mainStoryboard:UIStoryboard=UIStoryboard(name:"Main",bundle:nil)
            let desController=mainStoryboard.instantiateViewController(withIdentifier: "ReportViewController") as! ReportViewController
            let newFrontViewController=UINavigationController.init(rootViewController:desController)
            revealViewController.pushFrontViewController(newFrontViewController, animated: true)
        }
        
        if cell.lbName.text! == "Construction"
        {
            let mainStoryboard:UIStoryboard=UIStoryboard(name:"Main",bundle:nil)
            let desController=mainStoryboard.instantiateViewController(withIdentifier: "ConsViewController") as! ConsViewController
            let newFrontViewController=UINavigationController.init(rootViewController:desController)
            revealViewController.pushFrontViewController(newFrontViewController, animated: true)
        }
        
        if cell.lbName.text! == "Mark History"
        {
            let mainStoryboard:UIStoryboard=UIStoryboard(name:"Main",bundle:nil)
            let desController=mainStoryboard.instantiateViewController(withIdentifier: "HisViewController") as! HisViewController
            let newFrontViewController=UINavigationController.init(rootViewController:desController)
            revealViewController.pushFrontViewController(newFrontViewController, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if (section == tableView.numberOfSections - 1) {
            return 1
        }
        return 0
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
